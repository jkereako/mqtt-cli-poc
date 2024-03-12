//
//  MQTTCLIPOC.swift
//
//
//  Created by Jeff Kereakoglow on 3/12/24.
//

import Foundation

@main
struct MQTTCLIPOC {
    static func main() async throws {
        let connection = MQTTClientConnection(
            host: "test.mosquitto.org",
            port: 8886,
            clientIdentifier: "mqtt-client-ios-simulator"
        )

        await connection.connect()
        let payload = """
{
  "msg": "Published from the simulator"
}
"""
        let topic = "home/kitchen/light"
        await connection.publish(message: payload, topic: topic)
        
        var count = 0
        connection.messageHandler.messageReceived = { msg in
            count += 1
            print("\(count): \(msg)")
            
            // Shutdown the client after 5 messages
            if count >= 5 {
                Task {
                    await connection.shutdown()
                }
            }
        }
        
        // Suspsends here and listens for incoming messages.
        await connection.subscribe(to: [topic])
        
        print("Done!")
    }
}
