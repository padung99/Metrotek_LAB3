1) empty_o ошибки ( Transcript: empty_o: ... errors )
- После “reset”, empty_o должен быть = 1
  + Все Test case после сборса

2) almost_empty_o ошибки ( Transcript: almost_empty_o: ... errors )
- Сигнал определен неправильно, сигнал задержан на 1 такт
  + Test case 1: 5135 ps 

1) almost_full_o ошибки ( Transcript: almost_full_o: ... errors )
- Сигнал определен неправильно
  + Все Test case при usew_o = 2
  
4) usew_o ошибки ( Transcript: usew_o: ... errors )
- usew_o уменьшается хотя пустая очередь
  + Test case 3: 7845 ps  
- usew_o увеличивается хотя очередь полна
  + Test case 2: 7755 ps  
  + Test case 4: 10765 ps 


1) q_o ошибки ( Transcript: q_o: ... errors )
- Первое считанное значение неверно (По сравнению с значениями q_tb)
  + Test case 5: 14755 ps 
- В начале процесса чтения есть лишное значение
  + Test case 8: 23765 ps 
  + Test case 16: 86395 ps 
- Данные не правильно считаны (По сравнению с значениями q_tb)
  + Test case 6: 17405 ps 
- Выходные данные неправильно определен (По сравнению с значениями q_tb)
  + Test case 12: 72025 ps 
- Чтение из пустого lifo (Данные еще выводятся, пока lifo пуст)
  + Test case 4: 13385 ps  
- Первое выходное значение после пустого состояния было неправильно (По сравнению с значениями q_tb)
  + Test case 13: 74925 ps  
- Ошибка при чтении только 1 выходного значения (По сравнению с значениями q_tb)
  + Test case 14: 77565 ps 


1) reset error:
- Если srst_i = 1 когда rdreq = 1, у srst_i будет ошибка. Если после чтения будет idle(rdreq = 0 и wrreq = 0), результат сигнала "reset" будет нормальным как в остальных Test case
  + Test case 17: 99505 ps  (Reset должен начинаться на 99515 ps, и rdreq должен = 0 на 99515 ps )
 
