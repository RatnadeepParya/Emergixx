import 'package:emergixx_models/emergixx_models.dart';
import 'package:emergixx_crypto/emergixx_crypto.dart';
import 'package:emergixx_protocol/emergixx_protocol.dart';
import 'emergixx_test_framework.dart';

void main() {
  group('Store and Forward Multi-Hop Relay Tests', () {
    test('Simulates A -> B -> C -> D multi-hop relay with TTL decrement and hop count', () {
      final nodeA = IdentityKeys.generate();
      final nodeB = IdentityKeys.generate();
      final nodeC = IdentityKeys.generate();
      final nodeD = IdentityKeys.generate();

      final routerB = StoreAndForwardRouter(myDeviceId: nodeB.deviceId);
      final routerC = StoreAndForwardRouter(myDeviceId: nodeC.deviceId);
      final routerD = StoreAndForwardRouter(myDeviceId: nodeD.deviceId);

      // Node A originates message for Node D
      final now = DateTime.now().millisecondsSinceEpoch;
      final originalMsg = EmergixxMessage(
        messageId: 'multi-hop-msg-1',
        senderDeviceId: nodeA.deviceId,
        recipientDeviceId: nodeD.deviceId,
        messageType: MessageType.sos,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 10,
        hopCount: 0,
        priority: MessagePriority.critical,
        payload: 'EMERGENCY: Need medical assistance at camp site 4',
        signature: '',
        nonce: 'hop-nonce-1',
      );

      final sig = Signer.signMessage(message: originalMsg, seed: nodeA.seed);
      final signedMsgA = originalMsg.copyWith(signature: sig);

      // Hop 1: Node B receives from Node A
      final decisionB = routerB.handleIncomingPacket(signedMsgA);
      expect(decisionB, equals(RoutingDecision.relayedTransit));

      // Node B checks next messages to forward to Node C
      final peerC = Peer(
        peerId: nodeC.deviceId,
        ephemeralId: nodeC.deviceId,
        rssi: -65,
        lastSeen: DateTime.now(),
        transport: TransportType.bluetooth,
      );
      final forwardListB = routerB.getNextMessagesForPeer(peerC);
      expect(forwardListB.length, equals(1));
      final msgFromB = forwardListB.first;
      expect(msgFromB.hopCount, equals(1)); // Hop count incremented
      expect(msgFromB.ttl, equals(9)); // TTL decremented

      // Hop 2: Node C receives from Node B
      final decisionC = routerC.handleIncomingPacket(msgFromB);
      expect(decisionC, equals(RoutingDecision.relayedTransit));

      final peerD = Peer(
        peerId: nodeD.deviceId,
        ephemeralId: nodeD.deviceId,
        rssi: -60,
        lastSeen: DateTime.now(),
        transport: TransportType.bluetooth,
      );
      final forwardListC = routerC.getNextMessagesForPeer(peerD);
      expect(forwardListC.length, equals(1));
      final msgFromC = forwardListC.first;
      expect(msgFromC.hopCount, equals(2));
      expect(msgFromC.ttl, equals(8));

      // Hop 3: Node D (Final Destination) receives
      final decisionD = routerD.handleIncomingPacket(msgFromC);
      // Destination reached!
      expect(decisionD, equals(RoutingDecision.acceptedLocalOnly));

      // Node D verifies Node A's original signature across all hops!
      final isValidSig = Signer.verifyMessage(
        message: msgFromC,
        publicKey: nodeA.publicKey,
      );
      expect(isValidSig, isTrue);
    });

    test('Drops packets that exceed maximum hop limit (10 hops)', () {
      final node = IdentityKeys.generate();
      final router = StoreAndForwardRouter(myDeviceId: node.deviceId);

      final now = DateTime.now().millisecondsSinceEpoch;
      final maxHopMsg = EmergixxMessage(
        messageId: 'max-hop-msg',
        senderDeviceId: 'EX-ORIGIN',
        recipientDeviceId: 'EX-DESTINATION',
        messageType: MessageType.text,
        timestamp: now,
        createdAt: now,
        expiresAt: now + 3600000,
        ttl: 0, // Expired TTL
        hopCount: 10, // Max hops reached
        priority: MessagePriority.normal,
        payload: 'Stale transit',
        signature: 'sig',
        nonce: 'n-max',
      );

      final decision = router.handleIncomingPacket(maxHopMsg);
      expect(decision, equals(RoutingDecision.droppedHopLimit));
    });
  });

  printTestSummary();
}
