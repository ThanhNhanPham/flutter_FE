import 'package:flutter_bloc/flutter_bloc.dart';

// 🟢 Định nghĩa các sự kiện (Events)
abstract class CalculatorEvent {}

class NumberChanged extends CalculatorEvent {
  final double number1;
  final double number2;
  NumberChanged(this.number1, this.number2);
}

class OperationChanged extends CalculatorEvent {
  final String operation;
  OperationChanged(this.operation);
}

// 🟢 Định nghĩa các trạng thái (States)
class CalculatorState {
  final double number1;
  final double number2;
  final String operation;
  final double result;

  CalculatorState({
    required this.number1,
    required this.number2,
    required this.operation,
    required this.result,
  });

  CalculatorState copyWith({
    double? number1,
    double? number2,
    String? operation,
    double? result,
  }) {
    return CalculatorState(
      number1: number1 ?? this.number1,
      number2: number2 ?? this.number2,
      operation: operation ?? this.operation,
      result: result ?? this.result,
    );
  }
}

// 🟢 Bloc để xử lý logic
class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  CalculatorBloc()
      : super(CalculatorState(number1: 0, number2: 0, operation: "+", result: 0)) {
    on<NumberChanged>((event, emit) {
      double result = _calculate(event.number1, event.number2, state.operation);
      emit(state.copyWith(number1: event.number1, number2: event.number2, result: result));
    });

    on<OperationChanged>((event, emit) {
      double result = _calculate(state.number1, state.number2, event.operation);
      emit(state.copyWith(operation: event.operation, result: result));
    });
  }

  double _calculate(double num1, double num2, String operation) {
    switch (operation) {
      case "+":
        return num1 + num2;
      case "-":
        return num1 - num2;
      case "×":
        return num1 * num2;
      case "÷":
        return num2 != 0 ? num1 / num2 : 0;
      default:
        return 0;
    }
  }
}
