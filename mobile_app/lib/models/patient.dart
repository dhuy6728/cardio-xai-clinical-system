/// Data models for CardioXAI Mobile Client.
/// Maps directly to the FastAPI schemas.

class PatientInput {
  final double age;
  final int gender;
  final double height;
  final double weight;
  final int apHi;
  final int apLo;
  final int cholesterol;
  final int gluc;
  final int smoke;
  final int alco;
  final int active;
  final String patientName;
  final int? userId;

  PatientInput({
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.apHi,
    required this.apLo,
    required this.cholesterol,
    required this.gluc,
    required this.smoke,
    required this.alco,
    required this.active,
    this.patientName = "Bệnh nhân",
    this.userId,
  });

  Map<String, dynamic> toJson() => {
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'ap_hi': apHi,
        'ap_lo': apLo,
        'cholesterol': cholesterol,
        'gluc': gluc,
        'smoke': smoke,
        'alco': alco,
        'active': active,
        'patient_name': patientName,
        'user_id': userId,
      };

}

class FeatureContribution {
  final String feature;
  final String displayName;
  final double actualValue;
  final double shapValue;
  final String impact;

  FeatureContribution({
    required this.feature,
    required this.displayName,
    required this.actualValue,
    required this.shapValue,
    required this.impact,
  });

  factory FeatureContribution.fromJson(Map<String, dynamic> json) {
    return FeatureContribution(
      feature: json['feature'] ?? '',
      displayName: json['display_name'] ?? '',
      actualValue: (json['actual_value'] as num).toDouble(),
      shapValue: (json['shap_value'] as num).toDouble(),
      impact: json['impact'] ?? 'NEUTRAL',
    );
  }
}

class PredictionResult {
  final double riskProbability;
  final String riskPercentage;
  final String riskLevel;
  final int prediction;
  final double bmi;
  final String bmiCategory;
  final String recommendation;

  PredictionResult({
    required this.riskProbability,
    required this.riskPercentage,
    required this.riskLevel,
    required this.prediction,
    required this.bmi,
    required this.bmiCategory,
    required this.recommendation,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      riskProbability: (json['risk_probability'] as num).toDouble(),
      riskPercentage: json['risk_percentage'] ?? '0%',
      riskLevel: json['risk_level'] ?? 'LOW',
      prediction: json['prediction'] ?? 0,
      bmi: (json['bmi'] as num).toDouble(),
      bmiCategory: json['bmi_category'] ?? '',
      recommendation: json['recommendation'] ?? '',
    );
  }
}

class FullAnalysisResult {
  final int? recordId;
  final PredictionResult prediction;
  final List<FeatureContribution> shapContributions;
  final double baseValue;

  FullAnalysisResult({
    this.recordId,
    required this.prediction,
    required this.shapContributions,
    required this.baseValue,
  });

  factory FullAnalysisResult.fromJson(Map<String, dynamic> json) {
    final shapJson = json['shap_explanation'] ?? {};
    final list = (shapJson['contributions'] as List<dynamic>? ?? [])
        .map((e) => FeatureContribution.fromJson(e as Map<String, dynamic>))
        .toList();

    return FullAnalysisResult(
      recordId: json['record_id'],
      prediction: PredictionResult.fromJson(json['prediction'] ?? {}),
      shapContributions: list,
      baseValue: (shapJson['base_value'] as num? ?? 0.0).toDouble(),
    );
  }
}
