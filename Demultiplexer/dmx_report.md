Test đơn ( Chỉ test 1 trường hợp 1 lần, không dùng reset )
<!-- 1) random dir -- 6 packet ( 88 byte/packet) -- random ready
- Xuất hiện glitch và sau đó data bị nhảy sang 1 kênh (dir_i) khác)
- Test data_o:
- Test empty_o:
- Test channel_o:  -->

1) random dir -- 5 packet ( 49 byte/packet) -- ready = random
Run code: 
    fork
      ast_send_pk.send_pk(3);
      assert_ready(1,3,1,3);
      gen_dir();
      compare_output( fifo_packet_word );
    join_any
- Data bị nhảy sang 1 kênh khác ( 325 ps, packet phải truyền sang channel 0, nhưng ở packet này, chỉ có sop truyền ở channel 0, các byte data còn lại truyền sang channel 2 )
- Không có lỗi về data khi truyền từ snk sang các kênh src

2) dir_i = 3 -- 6 packet ( 88 byte/packet) -- random ready
- data truyền đúng kênh
- Test data_o:
- Test empty_o:
- Test channel_o:

3) dir_i = 2 -- 6 packet ( 88 byte/packet) -- random ready
- data truyền đúng kênh
- Test data_o:
- Test empty_o:
- Test channel_o:

4) dir_i = 1 -- 6 packet ( 88 byte/packet) -- random ready
- data truyền đúng kênh
- Test data_o:
- Test empty_o:
- Test channel_o:

5) dir_i = 0 -- 6 packet ( 88 byte/packet) -- random ready
- data truyền đúng kênh
- Test data_o:
- Test empty_o:
- Test channel_o:

6) random dir -- 6 packet ( 88 byte/packet) -- ready = 1 (Cố định ready, kt xem có bị lỗi chuyển kênh hay không) // assert_ready(100,100,0,0);
- Không có glitch 
- Không bị lỗi chuyển kênh nhưng có 1 kênh bị truyền dư dữ liệu ( 75 ps )
- Test data_o:
- Test empty_o:
- Test channel_o:

7) random dir -- 6 packet ( 88 byte/packet) -- ready = 0 (Cố định ready, kt xem có bị lỗi chuyển kênh hay không) // assert_ready(0,0,150,150);
- Không có glitch 
- Không bị lỗi chuyển kênh nhưng có 1 kênh bị truyền dư dữ liệu ( 75 ps )
- Test data_o: Không có data
- Test empty_o: Không có empty
- Test channel_o: Không có channel

//Test data
8) data < WORD_IN ( Số lượng byte trong 1 packet < 8 ) -- ready = 1 assert_ready(150,150,0,0);
- Không có lỗi về data

9) Random dir -- 5 packet ( 7byte/packet ) -- ready = random
- Không có lỗi chuyển kênh
- Không có lỗi data

10) Random dir -- 5 packet ( 8 byte/packet ) -- ready = random
- Không có lỗi chuyển kênh
- Không có lỗi data

11) Random dir -- 5 packet ( 9 byte/packet ) -- ready = random
- Không có lỗi chuyển kênh
- Không có lỗi data

12) Random dir -- 5 packet ( 1 byte/packet ) -- ready = random
Run code:
    gen_pk ( fifo_packet_byte, fifo_packet_word, 1, 1 );

    // // Test case 1: Random dir_i
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );
    fork
      ast_send_pk.send_pk(3);
      assert_ready(1,3,1,3);
      gen_dir();
      compare_output( fifo_packet_word );
    join_any
- ast_valid_o xuất hiện glitch ( 65 ps), không xác định được mức logic trong khi đầu vào ast_valid_i vẫn xác định bình thường













 