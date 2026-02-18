enum TravelLegType {
  outbound,
  internalLeg,
  returnLeg;

  String get label => switch (this) {
        outbound => 'Outbound',
        internalLeg => 'Internal',
        returnLeg => 'Return',
      };
}

enum TravelMode {
  flight,
  train,
  car,
  bus,
  ferry,
  other;

  String get label => switch (this) {
        flight => 'Flight',
        train => 'Train',
        car => 'Car',
        bus => 'Bus',
        ferry => 'Ferry',
        other => 'Other',
      };
}

enum DocumentParentType {
  holiday,
  accommodation,
  travelLeg,
  carHire,
  activity;

  String get label => switch (this) {
        holiday => 'Holiday',
        accommodation => 'Accommodation',
        travelLeg => 'Travel',
        carHire => 'Car Hire',
        activity => 'Activity',
      };
}
