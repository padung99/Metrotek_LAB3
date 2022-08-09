1) empty_o ошибки:
- После “reset”, empty_o должен быть = 1
  + Все тесты:  5 ps, Transcript: empty_o: ... errors

2) almost_empty_o ошибки:
- Сигнал определен неправильно, сигнал задержан на 1 такт
  + Test 1: 5149 ps, Transcript: almost_empty_o: ... errors

3) almost_full_o ошибки:
- Сигнал определен неправильно
  + Все тесты: 35 ps, Transcript: almost_full_o: ... errors

4) usew_o ошибки:
- Чтение из пустой очереди ( usew_o уменьшается хотя пустая очередь)
  + Test 3: 25 ps, Transcript: usew_o: ... errors
  + Test 1: 5165 ps, Transcript: usew_o: ... errors
- Запись в полную очередь ( usew_o увеличивается хотя очередь полна )
  + Test 2: 2575 ps, Transcript: : usew_o: ... errors
  + Test 4: 2585 ps, Transcript: : usew_o: ... errors

5) q_o ошибки:
- 1 значение было опущено в начале процесса чтения
  + Test 5: 75 ps, Transcript: q_o: ... errors
- В начале процесса чтения есть лишное значение
  + Test 8: 2655 ps, Transcript: q_o: ... errors
- Данные не могут быть считаны из-за ошибки в сигнале empty_o после сброса
  + Test 6: 35 ps, Transcript: q_o: ... errors