import 'package:equatable/equatable.dart';

/// Parsed data from the `c2pa.training-mining` assertion.
class TrainingMining extends Equatable {
  final bool doNotTrain;
  final bool doNotMine;
  final Map<String, dynamic>? entries;

  const TrainingMining({
    this.doNotTrain = false,
    this.doNotMine = false,
    this.entries,
  });

  factory TrainingMining.fromAssertionData(final Map<String, dynamic> data) {
    var doNotTrain = false;
    var doNotMine = false;

    if (data['entries'] is List) {
      for (final entry in data['entries'] as List) {
        if (entry is Map<String, dynamic>) {
          final use = entry['use'] as String?;
          final allowed =
              entry['constraint_info'] is Map
                  ? (entry['constraint_info'] as Map)['allowed'] as bool? ??
                      true
                  : true;

          if (use == 'notAllowed') {
            doNotTrain = true;
            doNotMine = true;
          } else if (!allowed) {
            if (use == 'training' || use == 'machineLearning') {
              doNotTrain = true;
            }
            if (use == 'dataMining') {
              doNotMine = true;
            }
          }
        }
      }
    }

    return TrainingMining(
      doNotTrain: doNotTrain,
      doNotMine: doNotMine,
      entries: data,
    );
  }

  @override
  List<Object?> get props => [doNotTrain, doNotMine, entries];
}
