# Chat MedGemma và SQLite

ChatBox Flutter gọi API Python này. Trọng số MedGemma, PDF và dữ liệu SQLite được cung cấp riêng, không nằm trong nội dung Git. Có thể lưu chúng trong `backend/runtime` (đã được Git bỏ qua) hoặc ở thư mục khác. Không đưa trọng số vào Flutter assets.

## Luồng ảnh → YOLO → ChatBox MedGemma

Code hiện làm tại `D:\DATA\.CODEX\DoAnVinhPhatNam\WebVinhNam_Server`. API dùng `lib/AI_Model/best.pt` trong repo. Với demo trên nhiều thiết bị, xem lệnh `Run-Server.ps1 -Lan` và cách chọn Gemini/MedGemma trong [README của dự án](../README.md). MedGemma được nạp từ thư mục riêng ngoài repo.

| ID thật trong best.pt | Class | Tên hiển thị |
| --- | --- | --- |
| 0 | tray_xuoc | Trầy xước |
| 1 | vet_cat_rach | Vết cắt, rách |
| 2 | bong | Bỏng |
| 3 | bam_tim | Bầm |

Đây là model **detection** của Ultralytics, trả về các vùng ảnh và class, không phải bộ phân loại luôn buộc mỗi ảnh vào một class.

1. Người dùng chọn/dán/chụp ảnh JPG, PNG, WEBP hoặc BMP, tối đa 10 MB/16 triệu điểm ảnh, rồi bấm quét.
2. Flutter gọi `POST /api/analyze-image` trên cùng API chat (cổng 8765). YOLO được nạp một lần và chạy trên **CPU** để dành GPU cho MedGemma. Không cần mở FastAPI/YOLO cổng 8000; app không còn tự khởi động server YOLO riêng.
3. API trả các vùng dự đoán và ID ngữ cảnh sống 30 phút. Ảnh không được ghi xuống ổ đĩa/SQLite. API chỉ lưu metadata dự đoán trong bộ nhớ, tối đa 64 lần phân tích. Ngưỡng 0,5 là quy tắc chuyển luồng của bản demo, chưa phải ngưỡng được đánh giá lâm sàng. Điểm model không phải xác suất chẩn đoán đúng.
4. Flutter tự chuyển sang **ChatBox AI**, hiển thị ảnh và kết quả YOLO ngay, rồi gọi `/api/chat` với ID đó. Tên class từ phía trình duyệt không được dùng để thay dự đoán đã lưu ở máy chủ.
5. **Ưu tiên SQLite:** khi có tài liệu đủ điều kiện cho nhóm nhận diện hoặc câu hỏi tiếp theo, API trả nội dung nguồn ngay trong ChatBox, giữ nguyên cảnh báo, phạm vi áp dụng và trích dẫn. Không gọi MedGemma để viết thêm đoạn mở đầu, không chờ model sinh lại nội dung đã có. Luồng này không sinh token và không phụ thuộc trạng thái sẵn sàng của MedGemma. Khi thiếu nguồn và cần trao đổi thêm, mới dùng MedGemma hiện tại; model nhận metadata YOLO, không trực tiếp xem ảnh. Không tự nâng nội dung thành duyệt chuyên môn.
6. Ảnh không rõ/nhiều class: hỏi thêm ngay, không mặc định trầy xước và không chờ model để hỏi câu làm rõ. Ảnh gợi ý bỏng: hỏi nguyên nhân ngay trước khi chọn quy trình bỏng nhiệt/hóa chất/điện. Người dùng mô tả nguyên nhân trong chat sẽ được tra nguồn tương ứng. Tên file không quyết định class, vị trí cơ thể hoặc mức độ.
7. Các câu hỏi tiếp theo trong cùng cuộc chat giữ ID ngữ cảnh ảnh. **Hội thoại mới** xóa ngữ cảnh đó; quét ảnh mới sẽ thay ngữ cảnh. Thử lại lỗi chat không chạy lại YOLO. Khi API khởi động lại hoặc ID hết hạn, cần quét lại ảnh.

Câu hỏi tiếp theo được xử lý theo **nội dung mới**, không dùng lại chỉ dẫn hỏi thêm của bước nhận diện ảnh. Ví dụ `tôi muốn biết cách sát trùng vết thương` được tra vào nhóm hướng dẫn làm sạch/chăm sóc vết thương; nếu có nguồn thì trả ngay. Câu ngắn như `vết này rửa thế nào` có thể dùng class ảnh làm gợi ý tra cứu; câu phủ định class, đổi sang triệu chứng khác hoặc hỏi chủ đề khác không bị ép vào class cũ. Nếu không có nguồn và cần MedGemma, lời nhắc hội thoại riêng yêu cầu trả lời câu hỏi hiện tại, không tự lặp lại nhận xét ảnh hay bịa mức độ tin cậy. Lời chào/cảm ơn vẫn được xử lý nhanh.

Các file chính: `backend/medgemma/wound_images.py`, `backend/medgemma/server.py`, `lib/core/medgemma_chat_api.dart`, `image_analysis_viewmodel.dart`, `chat_viewmodel.dart`, `chat_view.dart`. `backend/requirements.txt` đã có Ultralytics; dùng cùng Python có PyTorch CUDA của MedGemma. Bộ kiểm thử dùng kết quả ảnh giả lập để kiểm tra cả bốn class và kiểm tra không ép class khi ảnh không rõ; không thay thế đánh giá độ chính xác trên tập ảnh tổn thương được gán nhãn.

Trên máy hiện tại, SQLite, báo cáo đối chiếu và 7 PDF nằm trong `backend/runtime`. Trọng số MedGemma nằm ở thư mục `medgemma-1.5-4b-it` cùng cấp với repo.

## Tương thích giao diện cập nhật

- Camera và chọn/dán ảnh đều dùng cùng endpoint `/api/analyze-image`. Trên web không gọi `dart:io` để đọc đường dẫn file; đọc trực tiếp bytes do picker cung cấp. Clipboard file-path chỉ dùng trên nền tảng desktop có hỗ trợ.
- Payload có thể kèm `observations`: `heavy_bleeding`, `foreign_body`, `infection_signs`, mỗi giá trị là boolean. API chỉ chấp nhận ba khóa này và lưu dấu hiệu tự báo cáo cùng ID ngữ cảnh, không suy ra chúng từ class/điểm model.
- Khi có dấu hiệu cảnh báo tự báo cáo, tra nguồn tương ứng trước hướng dẫn chăm sóc thông thường. Nhiều dấu hiệu được giữ cùng lúc, gộp tài liệu theo ID và giữ đầy đủ điều kiện/cảnh báo/citation. Nguồn đã nghỉ sử dụng hoặc thay đổi không được dùng lại.
- Các lần chọn ảnh mới xóa checkbox cũ để tránh dùng nhầm dấu hiệu; lịch sử giữ ảnh thật, class và điểm thật, vị trí chưa được người dùng cung cấp thì ghi `Chưa xác định`.
- Việc tự khởi động server YOLO riêng được bỏ khỏi `main.dart`; chỉ chạy `Run-Chat.ps1` và một bản web. Các điều hướng/trang quản trị của bản `b983c2a` được giữ. Bản `WebVuVinhban1` không bị sửa.

## Người khác tải repo thì chạy thế nào?

Clone repo chỉ lấy code, chưa đủ để chạy đầy đủ chat. Có hai cách sử dụng:

- **Chạy AI trên máy riêng:** cài môi trường Python/PyTorch, tải MedGemma một lần và nhận bộ dữ liệu SQLite/PDF của nhóm theo các bước bên dưới. Máy cần GPU NVIDIA hỗ trợ CUDA cho cấu hình nạp hiện tại; 4 GB VRAM và khoảng 8 GB RAM có thể thiếu bộ nhớ khi nạp. Không mặc định mọi laptop đều chạy được.
- **Dùng API chung của nhóm:** chỉ một máy chủ nạp model và giữ kho dữ liệu. Web/app của các thành viên gọi API đó bằng `MEDGEMMA_API_BASE_URL`. Người dùng web/app không tải trọng số. Cần triển khai HTTPS, xác thực và cấu hình origin trước khi mở API ra ngoài; `127.0.0.1` chỉ trỏ tới chính máy đang truy cập.

### Thiết lập một máy Windows mới

Các lệnh sau chạy trong terminal tại thư mục repo vừa clone. Không cần tải lại model trên máy hiện tại nếu đã có bộ model hoạt động.

1. Cài Python 3.11 và Flutter. Tạo môi trường Python riêng trong repo:

   ```powershell
   py -3.11 -m venv .venv
   & ".\.venv\Scripts\python.exe" -m pip install --upgrade pip
   ```

2. Cài PyTorch có CUDA phù hợp với GPU/driver theo [hướng dẫn chính thức PyTorch](https://pytorch.org/get-started/locally/). Chạy lệnh cài bằng `& ".\.venv\Scripts\python.exe" -m pip` để thư viện nằm đúng môi trường. Sau đó cài các thư viện của chat và kiểm tra CUDA:

   ```powershell
   & ".\.venv\Scripts\python.exe" -m pip install -r backend\requirements.txt
   & ".\.venv\Scripts\python.exe" -c "import torch; print('CUDA:', torch.cuda.is_available())"
   ```

   Cần thấy `CUDA: True` trước khi nạp MedGemma với cấu hình hiện tại. File requirements không tự chọn bản PyTorch CUDA cho từng máy.

3. Mở [MedGemma trên Hugging Face](https://huggingface.co/google/medgemma-1.5-4b-it), đăng nhập tài khoản của người tải và chấp nhận điều kiện truy cập. Đăng nhập CLI rồi tải vào thư mục được Git bỏ qua:

   ```powershell
   & ".\.venv\Scripts\hf.exe" auth login
   & ".\.venv\Scripts\hf.exe" download google/medgemma-1.5-4b-it --local-dir ".\backend\runtime\models\medgemma-1.5-4b-it"
   ```

   Cách đăng nhập/tải theo [tài liệu Hugging Face CLI](https://huggingface.co/docs/huggingface_hub/guides/cli). Tài khoản cần có quyền truy cập model; không dùng chung token hay đẩy token lên Git. Chạy lại lệnh tải sẽ tận dụng các file đã tải. Backend hiện chỉ nạp từ file cục bộ, không tự tải model khi mở web.

4. Nhận bộ kho tài liệu của nhóm và giữ cấu trúc sau. Chỉ có file model sẽ chưa có các hướng dẫn và trích dẫn SQLite:

   ```text
   backend/runtime/
     models/medgemma-1.5-4b-it/       (được tải ở bước 3)
     knowledge_base/
       so_cuu.sqlite3
       demo_publication.json
       ket_qua_ra_soat.json
     TaiLieuNguon/
       ...các PDF đúng tên gốc...
   ```

   Dữ liệu trên máy dự án hiện nằm trong `backend/runtime/knowledge_base` và `backend/runtime/TaiLieuNguon` của repo mới. Dừng API đang dùng DB trước khi sao chép bộ dữ liệu, hoặc dùng bản sao lưu SQLite nhất quán. Giữ manifest, báo cáo và PDF đi cùng DB; không tự đổi trạng thái duyệt. Repo hiện không kèm bộ dữ liệu này, cần nhóm cung cấp riêng theo quyền sử dụng tài liệu.

5. Tạo cấu hình theo đường dẫn thực tế của máy mới. Đoạn sau chỉ tạo file nếu chưa có, giữ nguyên cấu hình sẵn có:

   ```powershell
   if (-not (Test-Path -LiteralPath '.\backend\.env.local')) {
       $modelDirectory = Join-Path (Get-Location).Path 'backend\runtime\models\medgemma-1.5-4b-it'
       $databaseFile = Join-Path (Get-Location).Path 'backend\runtime\knowledge_base\so_cuu.sqlite3'
       @(
           "MEDGEMMA_MODEL_PATH=$modelDirectory"
           "MEDGEMMA_KB_PATH=$databaseFile"
           'MEDGEMMA_ALLOW_LOCAL_WEB=1'
           'MEDGEMMA_ALLOWED_ORIGINS='
       ) | Set-Content -LiteralPath '.\backend\.env.local' -Encoding utf8
   }
   ```

6. Terminal thứ nhất chạy API với Python vừa tạo; terminal thứ hai chạy web:

   ```powershell
   .\Run-Chat.ps1 -Python ".\.venv\Scripts\python.exe"
   ```

   ```powershell
   .\Run-Web.ps1 -Flutter "D:\flutter\bin\flutter.bat"
   ```

   Thay đường dẫn Flutter nếu SDK nằm nơi khác. Đợi ChatBox báo model sẵn sàng rồi thử một câu khớp SQLite và một câu ngoài kho. Không cam kết tốc độ giống máy hiện tại vì phụ thuộc GPU/RAM/driver.

## Chạy trên máy hiện tại

Model đã được chuyển ra ngoài folder web, tại `D:\DATA\.CODEX\DoAnVinhPhatNam\medgemma-1.5-4b-it`. `backend/.env.local` đặt `MEDGEMMA_MODEL_PATH` trỏ đến đường dẫn này. Trọng số trên đĩa vẫn là BF16; mã Python tiếp tục nạp bằng NF4 4-bit, double quantization và SDPA như trước. Không có tệp adapter LoRA/fine-tune riêng trong bộ model đã kiểm tra. Nếu chuyển máy, cần sửa đường dẫn trong cấu hình; thư mục model không tự đi kèm `git push` hoặc `git clone`.

Mở hai terminal tại thư mục repo:

```powershell
.\Run-Chat.ps1
```

```powershell
.\Run-Web.ps1
```

`Run-Chat.ps1` dùng Python `D:\Models\medgemma-env\Scripts\python.exe`. Có thể đổi bằng `-Python`. `Run-Web.ps1` dùng SDK `D:\flutter\bin\flutter.bat` và có thể đổi bằng `-Flutter`. Web phát triển dùng cổng 8081. Nhận diện ảnh và chat dùng chung API cổng 8765.

Dùng `Build-Web.ps1` để tạo bản web demo, rồi chạy `Run-Server.ps1 -Lan` để phục vụ web và API từ một tiến trình. Mở `http://127.0.0.1:8080` trên máy chủ hoặc dùng địa chỉ LAN in trong terminal. Bản demo giảm lượng RAM cần cho trình biên dịch Flutter. Nhấn Ctrl+C trong terminal server để dừng. Build lại sau khi sửa mã Flutter.

Chỉ chạy một API MedGemma: dừng server/CLI MedGemma cũ trước khi chạy bản này. API giữ một model và khóa các yêu cầu sinh câu trả lời. Mở nhiều tab không nạp thêm model. YOLO chạy CPU và dùng chung tiến trình chat để tránh nạp thêm một bản PyTorch/GPU. Bản tích hợp này được kiểm tra cho Flutter Web.

Nếu chỉ thử kho tài liệu, dùng `Run-Chat.ps1 -NoPreload`; câu hỏi khớp nguồn vẫn tra SQLite ngay. `Nạp AI` trong chat sẽ nạp model trong cùng tiến trình. Nạp mặc định một lần khi API khởi động; trình duyệt không thể tự khởi động Python trên máy chủ.

## Cấu hình đường dẫn

Sao chép `.env.example` thành `.env.local` và điền đường dẫn trên máy. `.env.local` đã được bỏ qua bởi Git. Biến môi trường hệ thống được ưu tiên hơn file cấu hình.

- `MEDGEMMA_MODEL_PATH` trỏ đến thư mục model đã tải bằng tài khoản có quyền truy cập. Khi chạy bằng script dự án và để trống cấu hình này, server tìm `medgemma-1.5-4b-it` cùng cấp với repo. Nếu dùng đường dẫn tải ở bước 3, hãy đặt `MEDGEMMA_MODEL_PATH` theo đường dẫn đó.
- `MEDGEMMA_KB_PATH`: file `so_cuu.sqlite3`. Cùng thư mục phải có `demo_publication.json` và `ket_qua_ra_soat.json` nếu dùng tài liệu demo.
- PDF nằm đúng `relative_path` dưới thư mục cha của thư mục knowledge_base. Dữ liệu mặc định nằm dưới `backend/runtime/TaiLieuNguon` và `backend/runtime/knowledge_base`.
- `MEDGEMMA_ALLOW_LOCAL_WEB=1`: chỉ dành cho phát triển, cho phép các cổng localhost của Flutter truy cập API chat công khai. Không mở CORS cho API quản trị.
- `MEDGEMMA_ALLOWED_ORIGINS`: danh sách origin chính xác, phân cách bằng dấu phẩy.

API đọc lại trạng thái và dấu nội dung của các tài liệu. Không thay đổi trạng thái duyệt trong DB. Có nguồn: trả nội dung SQLite cùng điều kiện, cảnh báo và trang PDF. Thiếu nguồn: MedGemma tự trả lời với nhãn chưa đối chiếu nguồn. Cần xác nhận: người dùng chọn tài liệu hoặc dùng câu đã sửa. Lịch sử trên giao diện không tự đưa vào lượt hỏi mới. Dữ liệu không được tự ghi xuống cơ sở dữ liệu chat.

Một số câu xã giao hoàn chỉnh như `hello`, `cảm ơn bạn`, `alo tôi muốn đi chơi` có phản hồi trực tiếp với nhãn **Phản hồi nhanh của ứng dụng**. Đây là nội dung giao tiếp của ứng dụng, không phải câu trả lời do MedGemma sinh hoặc tài liệu đã duyệt. Chỉ khớp cả câu, không khớp từ khóa trong câu dài; câu có thêm triệu chứng, phủ định, lựa chọn tài liệu hoặc lịch sử không dùng lối tắt này. Những câu trò chuyện khác vẫn có thể cần model và còn chậm trên cấu hình hiện tại. Luồng y tế, tham số sinh và trọng số model được giữ nguyên.

## Triển khai sau này

1. Build Flutter: `flutter build web --dart-define=MEDGEMMA_API_BASE_URL=https://api.example.com/`. Đây là địa chỉ ví dụ, thay bằng API thực tế. Nếu để trống trên tên miền thật, web dùng `/api/...` cùng origin qua reverse proxy.
2. Host `build/web` trên dịch vụ web tĩnh. Chạy API Python riêng trên máy chủ có GPU, PyTorch CUDA phù hợp và thư viện trong `requirements.txt`.
3. Gắn volume dữ liệu, ví dụ `/data/models/medgemma-1.5-4b-it`, `/data/knowledge_base`, `/data/TaiLieuNguon`. Chép cả DB, báo cáo và manifest đi cùng; giữ cấu trúc đường dẫn PDF. Thiết lập `MEDGEMMA_MODEL_PATH`, `MEDGEMMA_KB_PATH` theo máy chủ mới. Không sử dụng đường dẫn ổ D trên Linux.
4. Tắt `MEDGEMMA_ALLOW_LOCAL_WEB`; chỉ cho phép origin web thực tế. API hiện nghe loopback; đặt reverse proxy HTTPS phía trước và chuyển Host nội bộ về `127.0.0.1:8765`. Cho phép body JSON tới 14 MB cho riêng `/api/analyze-image`, giới hạn thời gian chờ và số yêu cầu và bổ sung xác thực trước khi mở cho nhiều người dùng.
5. Chạy đúng một tiến trình model trên mỗi GPU; không bật nhiều worker hoặc tự reload model. Chuyển database sang Supabase không tự chuyển model lên Supabase.

Trạng thái đối chiếu nguồn bằng AI không phải duyệt chuyên môn. Bản demo hiện có 21 mục chờ duyệt; không tự đổi thành approved khi triển khai. Luồng ảnh chuyển sang ChatBox dùng chung API; các chức năng khác của nhóm vẫn được giữ.

## Kiểm tra

```powershell
python -B -m unittest discover -s backend -p "test_*.py" -q
flutter test test/chat_api_test.dart test/chat_widget_test.dart
```

`Run-Web.ps1` tạm tắt sinh plugin desktop trong phiên chạy web, tránh yêu cầu quyền tạo symlink Windows khi chỉ chạy Chrome; không sửa Developer Mode hoặc cấu hình Flutter toàn máy.
