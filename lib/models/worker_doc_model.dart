class WorkerDocModel {
  final String? cnicFront;
  final String? cnicBack;

  WorkerDocModel({this.cnicFront, this.cnicBack});

  factory WorkerDocModel.fromJson(Map<String, dynamic> json) {
    return WorkerDocModel(
      cnicFront: json['cnicFront'],
      cnicBack: json['cnicBack'],
    );
  }

  Map<String, dynamic> toJson() {
    return {"cnicFront": cnicFront, "cnicBack": cnicBack};
  }
}
