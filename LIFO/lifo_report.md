1) empty_o ошибки:
- После “reset”, empty_o должен быть = 1
  + Все Test case:  5 ps, Transcript: empty_o: ... errors

2) almost_empty_o ошибки:
- Сигнал определен неправильно, сигнал задержан на 1 такт
  + Test case 1: 5149 ps, Transcript: almost_empty_o: ... errors

3) almost_full_o ошибки:
- Сигнал определен неправильно
  + Все Test case: 35 ps, Transcript: almost_full_o: ... errors

4) usew_o ошибки:
- Чтение из пустой очереди ( usew_o уменьшается хотя пустая очередь)
  + Test case 3: 25 ps, Transcript: usew_o: ... errors
  + Test case 1: 5165 ps, Transcript: usew_o: ... errors
- Запись в полную очередь ( usew_o увеличивается хотя очередь полна )
  + Test case 2: 2575 ps, Transcript: : usew_o: ... errors
  + Test case 4: 2585 ps, Transcript: : usew_o: ... errors

5) q_o ошибки ( Transcript: q_o: ... errors )
- 1 значение было опущено в начале процесса чтения
  + Test case 5: 75 ps
- В начале процесса чтения есть лишное значение
  + Test case 8: 2655 ps, 
- Данные не могут быть считаны из-за ошибки в сигнале empty_o после сброса
  + Test case 6: 35 ps
- Выходное значение не определено
  + Test case 9: 955 ps

