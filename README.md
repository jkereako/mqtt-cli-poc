# MQTT CLI POC
This is a very simple POC to test MQTT. I have never worked with this 
technology before.

This project is hardcoded to use Mosquitto's public encrypted broker. It
publishes a message on start up and listens to messages on the topic
"home/kitchen/light".

To verify the topic subscription works, download [MQTTX][3] and connect to the
same broker as this program and publish a message to the same topic. You will
see the message printed to the console.

## Technical details
This MQTT implementation is built on top of [MQTT NIO][4]. It provides a simple
interface to subscribe and publish to topics.

## Credit
The class MQTTClientConnection was lifted from the project [EmCuTeeTee][1]. It
is the best and simplest example of how to use MQTT NIO.

# Resources
- [EmCuTeeTee][1]
- [Mosquitto test broker][2]
- [MQTTX][3]
- [MQTT NIO][4]

[1]: https://github.com/adam-fowler/EmCuTeeTee
[2]: https://test.mosquitto.org
[3]: https://mqttx.app
[4]: https://github.com/swift-server-community/mqtt-nio
