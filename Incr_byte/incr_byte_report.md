//////////////////////////////NON USING BFM ///////////////////////////////
Testcase 2:
[base_addr =  0x3fc, length =  45 bytes -- amm_rd_waitrequest = 1'b0 -- amm_wr_waitrequest = random -- readdatavalid = random] 
- amm_wr_byteenable_o: 385 ps, ошибка в последнем слове 0x1f, результат здесь должен быть 0xff Эта ошибка приведет к неправильному приему данных в write_data_fifo ==> потеряно 3 байта.

Testcase 4:
[base_addr =  0x10, length = 8 bytes]
- waitrequest_o: 635 ps, в начале работы, поэтому waitrequest_o должен быть = 1'b1, но тут waitrequest_o = 1'b0, остальные таски не могут запускать.

Testcase 5:
[ base_addr =  0x10, length = 16 bytes -- amm_rd_waitrequest = random -- amm_wr_waitrequest = random -- readdatavalid = random ]
- amm_wr_byteenable_o: 845 ps, тут amm_wr_byteenable_o не должен быть = 0x00, а должен быть = 0xff, Эта ошибка приведет к неправильному приему данных в write_data fifo ==> потеряно 1 слово ( 8 bytes )

Testcase 6:
[ base_addr =  0x10, length = 24 bytes -- amm_rd_waitrequest = random -- amm_wr_waitrequest = random -- readdatavalid = random ]
- amm_wr_byteenable_o: 1115 ps, тут amm_wr_byteenable_o не должен быть = 0x00, а должен быть = 0xff, Эта ошибка приведет к неправильному приему данных в write_data fifo ==> потеряно 1 слово ( 8 bytes )

Testcase 10:
[ base_addr =  0x3fc, length = 33 bytes -- amm_rd_waitrequest = random -- amm_wr_waitrequest = random -- readdatavalid = random  ]
- amm_wr_byteenable_o: 1955 ps, тут amm_wr_byteenable_o не должен быть = 0x00, а должен быть = 0xff, Эта ошибка приведет к неправильному приему данных в write_data fifo ==> потеряно 1 слово ( 8 bytes )

Testcase 11:
[ base_addr =  0x10, length = 1 byte -- amm_rd_waitrequest = random -- amm_wr_waitrequest = random -- readdatavalid = random ]
- amm_wr_data_o: 2075 ps, wr_data не идентифицирован, 0xff + 0x01 = 0x00, а не xx

Testcase 12:
[ base_addr =  0x00, length = 10'b1111111111 bytes -- amm_rd_waitrequest = random amm_wr_waitrequest = random -- readdatavalid = random ]
- amm_wr_address_o : 6935 ps, запись останавливается по адресу 0x7e, а waitrequest_o выполняется вечно. Но запись и waitrequest_o должны были остановить последний адрес (0x7f)


//////////////////////////////USING BFM ///////////////////////////////
Testcase 2: //
[base_addr =  0x3fc, length =  45 bytes -- amm_rd_waitrequest = 1'b0 -- amm_wr_waitrequest = random -- readdatavalid = random] 
- amm_wr_byteenable_o: 5300 ps, ошибка в последнем слове 0x1f, результат здесь должен быть 0xff Эта ошибка приведет к неправильному приему данных в write_data_fifo ==> потеряно 3 байта.

Testcase 4: //
[base_addr =  0x10, length = 8 bytes]
- waitrequest_o: 8300 ps, в начале работы, поэтому waitrequest_o должен быть = 1'b1, но тут waitrequest_o = 1'b0, остальные таски не могут запускать.

Testcase 5: //
[ base_addr =  0x10, length = 16 bytes -- amm_rd_waitrequest = random -- amm_wr_waitrequest = random -- readdatavalid = random ]
- amm_wr_byteenable_o: 11300 ps, тут amm_wr_byteenable_o не должен быть = 0x00, а должен быть = 0xff, Эта ошибка приведет к неправильному приему данных в write_data fifo ==> потеряно 1 слово ( 8 bytes )

Testcase 6: //
[ base_addr =  0x10, length = 24 bytes -- amm_rd_waitrequest = random -- amm_wr_waitrequest = random -- readdatavalid = random ]
- amm_wr_byteenable_o: 14100 ps, тут amm_wr_byteenable_o не должен быть = 0x00, а должен быть = 0xff, Эта ошибка приведет к неправильному приему данных в write_data fifo ==> потеряно 1 слово ( 8 bytes )

Testcase 10: // 
[ base_addr =  0x3fc, length = 33 bytes -- amm_rd_waitrequest = random -- amm_wr_waitrequest = random -- readdatavalid = random  ]
- amm_wr_byteenable_o: 25700 ps, тут amm_wr_byteenable_o не должен быть = 0x00, а должен быть = 0xff, Эта ошибка приведет к неправильному приему данных в write_data fifo ==> потеряно 1 слово ( 8 bytes )

Testcase 11: //
[ base_addr =  0x10, length = 1 byte -- amm_rd_waitrequest = random -- amm_wr_waitrequest = random -- readdatavalid = random ]
- amm_wr_data_o: 27700 ps, wr_data не идентифицирован, 0xff + 0x01 = 0x00, а не xx



