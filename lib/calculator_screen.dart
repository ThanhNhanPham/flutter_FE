import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'calculator_bloc.dart';

class CalculatorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CalculatorBloc(),
      child: Scaffold(
        appBar: AppBar(title: Text("Máy tính với BLoc")),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              BlocBuilder<CalculatorBloc, CalculatorState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: "Số thứ nhất"),
                        onChanged: (value) {
                          double number1 = double.tryParse(value) ?? 0;
                          context.read<CalculatorBloc>().add(
                            NumberChanged(number1, state.number2),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: "Số thứ hai"),
                        onChanged: (value) {
                          double number2 = double.tryParse(value) ?? 0;
                          context.read<CalculatorBloc>().add(
                            NumberChanged(state.number1, number2),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            ["+", "-", "×", "÷"].map((op) {
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    context.read<CalculatorBloc>().add(
                                      OperationChanged(op),
                                    );
                                  },
                                  child: Text(
                                    op,
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                      SizedBox(height: 20),
                      Card(
                        elevation: 5, // Hiệu ứng đổ bóng
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: Colors.deepPurpleAccent, // Màu nền đẹp hơn
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 40,
                          ),
                          child: Text(
                            "Kết quả: ${state.result}",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Màu chữ nổi bật
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
