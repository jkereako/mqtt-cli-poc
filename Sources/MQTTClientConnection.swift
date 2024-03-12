//
//  MQTTClientConnection.swift
//
//
//  Created by Jef Kereakoglow on 3/12/24.
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
    var shuttingDown: Bool
    let listener: MQTTPublishListener
    let name = "MQTTClientConnection"
    let logger: Logger

    init(
        host: String,
        port:Int = 1883,
        clientIdentifier: String,
        username: String? = nil,
        password: String? = nil,
        shouldVerifyCertificate: Bool = true) {
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
            shuttingDown = false
            listener = client.createPublishListener()
            
            // Add the close listener here so it's only executed once
            client.addCloseListener(named: name) { result in
                guard !self.shuttingDown else { return }
                
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
        self.shuttingDown = true
        client.removeCloseListener(named: name)
        try? await self.client.disconnect()
        try? await self.client.shutdown()
    }

    func publish(
        topic: String,
        message: String,
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

    func subscribe(topic: String) async {
        do {
            let ack = try await client.subscribe(
                to: [
                    MQTTSubscribeInfo(topicFilter: topic, qos: .exactlyOnce)
                ]
            )
            
            logger.log(level: .info, "Subscribed to \(topic)")
            
            for await result in listener {
                switch result {
                case .success(let publishInfo):
                    guard publishInfo.topicName == topic else {
                        logger.log(
                            level: .info,
                            "Received message from topic \"\(publishInfo.topicName)\", but expected topic \"\(topic)\"."
                        )
                        continue
                    }
                    
                    var buffer = publishInfo.payload
                    let string = buffer.readString(length: buffer.readableBytes)
                    print(string!)
                    
                case .failure(let error):
                    print(
                        "Error while receiving publish event: \(error.localizedDescription)"
                    )
                }
            }

        } catch {
            logger.log(
                level: .info, "Failed to subscribe to \(topic)\nError: \(error)"
            )
        }
    }

    func unsubscribe(topic: String) async {
        do {
            _ = try await self.client.unsubscribe(from: [topic])
            logger.log(level: .info, "Unsubscribed from \(topic)")
        } catch {
            logger.log(
                level: .info, "Failed to unsubscribe from \(topic)\nError: \(error)"
            )
        }
    }
}
