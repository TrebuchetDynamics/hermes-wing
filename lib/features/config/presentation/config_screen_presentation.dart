import '../../../core/channel/navivox_channel.dart';
import '../../profile_contacts/profile_contact_presentation.dart';
import '../apply/config_apply_flow_model.dart';
import '../apply/config_apply_presentation.dart';
import '../form/config_draft_session.dart';
import '../form/config_form_model.dart';
import 'config_section_presentation.dart';

class ConfigScreenPresentation {
  const ConfigScreenPresentation._({
    required this.scope,
    required this.sections,
    required this.applyFlow,
    required this.applyPresentation,
    required this.isEmpty,
    this.missingSectionId,
  });

  factory ConfigScreenPresentation.fromState({
    required NavivoxChannelState state,
    required ConfigDraftSession draftSession,
    String? sectionId,
  }) {
    final form = ConfigFormModel.fromSchema(
      schema: state.configSchema,
      values: state.configValues,
    );
    final isEmpty = form.rows.isEmpty;
    final sectionSelection = form.selectSection(sectionId);
    final applyFlow = ConfigApplyFlowModel.fromDraft(
      form: form,
      draftValues: draftSession.draftValues,
      validationSnapshot: state.configDiff,
    );
    final selectedSections = isEmpty || sectionSelection.isMissing
        ? const <ConfigFormSection>[]
        : sectionSelection.sections;

    return ConfigScreenPresentation._(
      scope: ProfileContactScopePresentation(
        activeServer: state.activeServer,
        activeServerId: state.activeServerId,
        activeProfile: state.activeProfileContact,
      ),
      sections: selectedSections
          .map(
            (section) => ConfigSectionPresentation.fromSection(
              section,
              applyFlow: applyFlow,
              editingField: draftSession.editingField,
            ),
          )
          .toList(growable: false),
      applyFlow: applyFlow,
      applyPresentation: ConfigApplyPresentation.fromFlow(applyFlow),
      isEmpty: isEmpty,
      missingSectionId: isEmpty ? null : sectionSelection.missingId,
    );
  }

  final ProfileContactScopePresentation scope;
  final List<ConfigSectionPresentation> sections;
  final ConfigApplyFlowModel applyFlow;
  final ConfigApplyPresentation applyPresentation;
  final bool isEmpty;
  final String? missingSectionId;

  String get emptyMessage => 'No config available';

  bool get isMissingSection => missingSectionId != null;

  String get missingSectionMessage =>
      'Config section not found: $missingSectionId';

  bool get showPendingChanges => applyPresentation.hasChanges;
}
