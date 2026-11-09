/**
 * CardioCare AI - Cardiovascular AI Inference Engine
 * Approximates Gradient Boosting / Logistic Regression risk function
 * and SHAP factor impact attributions based on ESC / AHA guidelines.
 */

function calculateBMI(weightKg, heightCm) {
  if (!weightKg || !heightCm || heightCm <= 0) return 0;
  return parseFloat((weightKg / Math.pow(heightCm / 100, 2)).toFixed(2));
}

function evaluateCardioRisk(params) {
  const bmi = calculateBMI(params.weight, params.height);
  let z = -5.15;
  z += (params.age - 30) * 0.056;

  if (params.ap_hi > 140) {
    z += (params.ap_hi - 120) * 0.036 + 0.35;
  } else if (params.ap_hi > 120) {
    z += (params.ap_hi - 120) * 0.024;
  } else {
    z += (params.ap_hi - 120) * 0.015;
  }

  if (params.ap_lo > 90) {
    z += (params.ap_lo - 80) * 0.022;
  } else {
    z += (params.ap_lo - 80) * 0.01;
  }

  if (params.chol === 1) z -= 0.25;
  else if (params.chol === 2) z += 0.55;
  else if (params.chol === 3) z += 1.35;

  if (params.gluc === 1) z -= 0.10;
  else if (params.gluc === 2) z += 0.30;
  else if (params.gluc === 3) z += 0.75;

  if (bmi > 25) {
    z += (bmi - 22) * 0.065;
  } else {
    z += (bmi - 22) * 0.02;
  }

  if (params.smoke === 1) z += 0.45;
  if (params.alco === 1) z += 0.15;
  if (params.active === 1) z -= 0.40;
  if (params.gender === 2) z += 0.18;

  const prob = Math.min(Math.max(1 / (1 + Math.exp(-z)), 0.02), 0.98);

  let level = "Nguy cơ thấp";
  let color = "#16A34A";
  let badge = "badge-low";
  let advice = "";

  if (prob >= 0.65) {
    level = "Nguy cơ cao";
    color = "#DC2626";
    badge = "badge-high";
    advice = "Nguy cơ tim mạch đang ở mức cao. Các chỉ số cho thấy thành mạch máu và tim đang chịu áp lực lớn. Bạn nên đến bệnh viện hoặc phòng khám chuyên khoa tim mạch sớm để được đo điện tim (ECG), siêu âm tim và lập phác đồ kiểm soát.";
  } else if (prob >= 0.35) {
    level = "Nguy cơ trung bình";
    color = "#D97706";
    badge = "badge-mod";
    advice = "Bạn đang có các yếu tố nguy cơ tim mạch tiềm ẩn. Cần đo huyết áp định kỳ tại nhà 2 lần/tuần, giảm lượng muối ăn, kiểm soát cân nặng và duy trì vận động thể thao 150 phút/tuần.";
  } else {
    level = "Nguy cơ thấp (An toàn)";
    color = "#16A34A";
    badge = "badge-low";
    advice = "Chúc mừng bạn! Trái tim của bạn hiện đang có các chỉ số nằm trong dải bảo vệ an toàn. Tiếp tục duy trì chế độ dinh dưỡng lành mạnh, ăn nhiều rau quả và khám sức khỏe định kỳ hàng năm.";
  }

  const factors = [
    { name: `Huyết áp tâm thu (${params.ap_hi} mmHg)`, impact: params.ap_hi > 120 ? (params.ap_hi - 120) * 0.4 : -8, isRisk: params.ap_hi > 120 },
    { name: `Mức Cholesterol (${params.chol === 1 ? 'Bình thường' : params.chol === 2 ? 'Hơi cao' : 'Rất cao'})`, impact: params.chol === 3 ? 24 : params.chol === 2 ? 12 : -10, isRisk: params.chol > 1 },
    { name: `Độ tuổi (${params.age} tuổi)`, impact: (params.age - 35) * 0.5, isRisk: params.age > 45 },
    { name: `Chỉ số thể trạng BMI (${bmi.toFixed(1)} kg/m²)`, impact: (bmi - 22) * 1.2, isRisk: bmi > 24 },
    { name: `Thuốc lá (${params.smoke === 1 ? 'Có hút' : 'Không hút'})`, impact: params.smoke === 1 ? 18 : -5, isRisk: params.smoke === 1 },
    { name: `Vận động (${params.active === 1 ? 'Đều đặn' : 'Ít vận động'})`, impact: params.active === 1 ? -15 : 12, isRisk: params.active === 0 }
  ];

  return {
    prob: prob,
    level: level,
    color: color,
    badge: badge,
    bmi: bmi,
    advice: advice,
    factors: factors
  };
}
