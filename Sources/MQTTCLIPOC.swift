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
        await connection.publish(topic: topic, message: payload)
        
        // Suspsends here and listens for incoming messages. To break this, you'll
        // need to call `connection.shutdown()` (I think)
        await connection.subscribe(topic: topic)
    }
}
