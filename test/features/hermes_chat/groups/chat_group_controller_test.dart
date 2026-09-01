import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wing/features/hermes_chat/gateways/gateway_contact.dart';
import 'package:wing/features/hermes_chat/groups/chat_group_controller.dart';

void main() {
  const architect = GatewayContactId(
    gatewayId: 'wing-host',
    profileId: 'architect',
  );

  test(
    'creates a group and assigns a gateway-scoped profile contact',
    () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ChatGroupController(idFactory: () => 'group-1');
      await controller.load();

      await controller.createGroup('Hermes Wing');
      await controller.moveContact(architect, 'group-1');

      expect(controller.groups.single.name, 'Hermes Wing');
      expect(controller.groupIdFor(architect), 'group-1');

      final restored = ChatGroupController();
      await restored.load();
      expect(restored.groups.single.name, 'Hermes Wing');
      expect(restored.groupIdFor(architect), 'group-1');
    },
  );

  test(
    'renames a group and deleting it returns contacts to ungrouped',
    () async {
      SharedPreferences.setMockInitialValues({});
      final controller = ChatGroupController(idFactory: () => 'group-1');
      await controller.load();
      await controller.createGroup('Wing');
      await controller.moveContact(architect, 'group-1');

      await controller.renameGroup('group-1', 'Hermes Wing');
      expect(controller.groups.single.name, 'Hermes Wing');

      await controller.deleteGroup('group-1');
      expect(controller.groups, isEmpty);
      expect(controller.groupIdFor(architect), isNull);
    },
  );
}
