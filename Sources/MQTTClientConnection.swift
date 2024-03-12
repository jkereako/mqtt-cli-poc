//
//  MQTTClientConnection.swift
//
//
//  Created by Jeff Kereakoglow on 3/12/24.
//

import Foundation
import Logging
import MQTTNIO
import NIOCore
import NIOTransportServices

final class MQTTClientConnection {
    // I don't know why, but we need this for this thing to work.
    static let eventLoopGroup = NIOTSEventLoopGroup()
    let client: MQTTClient
    let listener: MQTTPublishListener
    let name = "MQTTClientConnection"
    let logger: Logger
    var messageHandler: MessageHandler
    
    private var isShuttingDown: Bool
    
    init(
        host: String,
        port:Int = 1883,
        clientIdentifier: String,
        username: String? = nil,
        password: String? = nil,
        shouldVerifyCertificate: Bool = true,
        messageHandler: MessageHandler = .defaultWitness) {
            var tlsConfig = TSTLSConfiguration(certificateVerification: .none)
            
            if shouldVerifyCertificate {
                tlsConfig.certificateVerification = .fullVerification
            }
            
            let config = MQTTClient.Configuration(
                version: .v5_0,
                userName: username,
                password: password,
                useSSL: true,
                tlsConfiguration: .ts(tlsConfig)
            )

            let logger = Logger(label: name)
            
            self.logger = logger
            self.client = .init(
                host: host,
                port: port,
                identifier: clientIdentifier,
                eventLoopGroupProvider: .shared(Self.eventLoopGroup),
                logger: logger,
                configuration: config
            )
            isShuttingDown = false
            listener = client.createPublishListener()
            self.messageHandler = messageHandler
            
            // Add the close listener here so it's only executed once
            client.addCloseListener(named: name) { result in
                guard !self.isShuttingDown else { return }
                
                self.logger.log(level: .info, "Connection closed")
                self.logger.log(
                    level: .info, "Reconnecting to \(self.client.host):\(self.client.port)"
                )
                
                Task {
                    // Attempt to reconnect
                    await self.connect()
                }
            }
        }
    
    func connect() async {
        do {
            let _ = try await client.connect(cleanSession: true)
            
            logger.log(
                level: .info, "Connected to \(client.host):\(client.port)"
            )
            
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }

    func shutdown() async {
        logger.log(
            level: .info, "Terminating connection to \(client.host):\(client.port)"
        )
        
        isShuttingDown = true
        client.removeCloseListener(named: name)
        try? await self.client.disconnect()
        try? await self.client.shutdown()
    }

    func publish(
        message: String,
        topic: String,
        qos: Int = 0,
        shouldRetainMessage: Bool = false) async {
            do {
                try await self.client.publish(
                    to: topic,
                    payload: ByteBufferAllocator().buffer(string: message),
                    qos: .init(rawValue: UInt8(qos)) ?? .atMostOnce,
                    retain: shouldRetainMessage
                )
                logger.log(
                    level: .info, "Published to \(topic)"
                )
            } catch {
                logger.log(
                    level: .info, "Failed to publish to \(topic)\nError: \(error)"
                )
            }
        }

    func subscribe(to topics: [String]) async {
        do {
            let subscriptions = topics.map {
                MQTTSubscribeInfo(topicFilter: $0, qos: .exactlyOnce)
            }

            // TODO: Handle the acknowledgement
            let ack = try await client.subscribe(to: subscriptions)
            
            logger.log(level: .info, "Subscribed to \(topics)")
            
            for await result in listener {
                switch result {
                case .success(let publishInfo):
                    let topic = publishInfo.topicName
                    
                    guard topics.contains(topic) else {
                        logger.log(
                            level: .info,
                            "Received message from topic \"\(topic)\", but expected topics \"\(topics)\"."
                        )
                        continue
                    }
                    
                    var buffer = publishInfo.payload
                    guard let msg = buffer.readString(length: buffer.readableBytes) 
                    else {
                        logger.log(
                            level: .info,
                            "Received message from topic \"\(topic)\", but failed to read message."
                        )
                        continue
                    }
                    
                    messageHandler.messageReceived(msg)
                    
                case .failure(let error):
                    print(
                        "Error while receiving publish event: \(error.localizedDescription)"
                    )
                }
            }

        } catch {
            logger.log(
                level: .info, "Failed to subscribe to \(topics)\nError: \(error)"
            )
        }
    }

    func unsubscribe(from topics: [String]) async {
        do {
            _ = try await self.client.unsubscribe(from: topics)
            logger.log(level: .info, "Unsubscribed from \(topics)")
        } catch {
            logger.log(
                level: .info, "Failed to unsubscribe from \(topics)\nError: \(error)"
            )
        }
    }
}
