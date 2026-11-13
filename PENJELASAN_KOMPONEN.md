# Penjelasan Singkat Fungsi Komponen UI

| Komponen | Fungsi |
|---|---|
| **Header (IoT Monitoring)** | Judul aplikasi dan subjudul dashboard. |
| **Status Chip (Connected/Disconnected)** | Menampilkan status koneksi MQTT. Di versi dummy, chip dapat di-tap untuk simulasi berubah status. |
| **Kartu Temperature** | Menampilkan nilai suhu terakhir dari sensor DHT11 (dummy). |
| **Kartu Humidity** | Menampilkan nilai kelembapan terakhir dari sensor DHT11 (dummy). |
| **Kartu MQTT Connection** | Menampilkan informasi broker, topic, dan waktu pembaruan data terakhir (Last Update). |
| **Monitoring History - Grafik** | Grafik garis perubahan suhu (opsional). Tombol *Expand chart* memperbesar grafik. |
| **Monitoring History - Tabel** | Daftar riwayat waktu dan nilai suhu. |
| **Timer simulasi** | Menghasilkan data acak tiap 5 detik sebagai pengganti data MQTT asli. |
