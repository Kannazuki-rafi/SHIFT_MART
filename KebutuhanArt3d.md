# Kebutuhan 3D Art — SHIFT MART

Daftar ini sesuai dengan isi game sekarang. Jumlah di bawah adalah model unik; objek yang berulang bisa memakai model yang sama.

| Kelompok | Model yang dibuat | Catatan |
|---|---|---|
| Pemain | 1 troli belanja | Keranjang terbuka, pegangan, rangka bawah, empat roda. Siluet harus mudah dikenali dari kamera belakang. |
| Pemain | 1 pengendara sederhana | Badan, kepala, tangan memegang pegangan. Dipakai ulang untuk empat pemain. |
| Pemain | Isi belanjaan troli | Beberapa produk sederhana sebagai dekorasi di dalam keranjang. |
| Lingkungan | Lantai modular | Potongan lantai supermarket yang bisa diulang. |
| Lingkungan | Dinding modular | Segmen lurus dan sudut; jangan terlalu tinggi sampai menutupi pemain. |
| Lingkungan | Rak supermarket dua sisi | Untuk deretan rak tengah; bisa memakai modul berulang. |
| Lingkungan | Meja/display sayur dan buah | Untuk area Produce. |
| Lingkungan | Lemari freezer | Untuk area Freezer; bentuk sederhana dengan panel kaca. |
| Lingkungan | Meja kasir + scanner | Untuk area Checkout dan tema garis finish. |
| Lingkungan | Pallet kayu | Penghalang kecil di lintasan. |
| Lingkungan | Tumpukan kardus | Dekorasi stockroom; bisa disusun dari satu model kardus. |
| Jalur | Gate/palang bergerak | Satu desain, dengan variasi warna Blue dan Orange. Bagian bergerak harus terpisah dari rangka. |
| Jalur | Lampu peringatan gate | Satu model; warna/material diubah melalui kode. |
| Jalur | Gerbang/papan finish | Tiang dan papan bertema checkout. Area tulisan disediakan kosong. |
| Jalur | Papan nama area | Satu desain yang dipakai ulang untuk Produce, Freezer, dan Checkout. |
| Dekorasi | 3 bentuk produk | Botol, kaleng kemasan, dan kotak/kardus produk. Bisa dipakai mengisi rak dan troli. |
| Item | Kulit pisang terbuka | Harus terbaca sebagai jebakan dari atas/belakang. |
| Item | Kaleng minuman lempar | Satu model dipakai untuk pickup dan proyektil. Warna mencolok agar mudah terlihat. |
| Pickup | Penanda pad pickup | Model tipis/rata di lantai. Item melayang di atasnya; jalur harus tetap bisa dilewati. |
| Hazard | Papan lantai licin | Papan kecil “wet floor” di dekat genangan. |
| Hazard | Lemari/rak yang bisa roboh | Satu model dipakai di tiga lokasi. Ukuran placeholder 3 m lebar, 5 m tinggi, 1 m dalam. Pivot di tengah bawah; jatuh ke arah lokal -Z. Isi rak ikut sebagai anak objek. Area peringatan merah dibuat oleh kode. |
| Hazard | Buah jatuh | Dua variasi warna/bentuk sederhana, misalnya jeruk dan apel. Lima buah per kejadian; pisahkan dari model rak agar bisa dianimasikan dan hilang saat terinjak. |
| Lingkungan | Display bakery | Meja roti rendah dan produk roti sederhana untuk mengisi area tengah. |

## Pemisahan komponen troli

Pisahkan objek berikut agar animasi yang sudah ada bisa dipakai:

- Empat roda, masing-masing dengan pivot tepat di pusat roda.
- Pengendara sebagai objek terpisah agar bisa miring saat berbelok.
- Rangka/keranjang sebagai kelompok tersendiri untuk efek ambruk.
- Bagian warna pemain memakai material tersendiri: lime, biru, oranye, dan merah muda.

Troli rusak saat ini diwakili roda bengkok dan badan yang mengempis saat hancur. Model rusak tambahan bersifat opsional; satu model troli yang komponennya terpisah sudah cukup untuk tahap awal.

## Pedoman file dan ukuran

- Gaya: low-poly, material sederhana, warna jelas.
- Format: `.glb`.
- Skala: 1 unit = 1 meter; atas +Y, arah depan troli -Z.
- Ukuran troli awal: sekitar 1,2 m lebar × 1,6 m panjang; hindari perubahan besar karena collider dan lintasan sudah disetel.
- Origin troli: tengah bagian bawah, sejajar lantai.
- Terapkan transform sebelum ekspor dan beri nama objek/material dengan jelas.
- Collision dibuat di Godot; art tidak perlu memakai mesh collision yang detail.

Panah lantai, pola kotak finish, genangan, teks papan, dan lampu berwarna sudah bisa dibuat lewat kode/material. Tidak perlu model 3D khusus untuk bagian-bagian itu.

## Urutan pengerjaan

1. Troli dan pengendara.
2. Rak, freezer, dan kasir.
3. Banana dan can.
4. Aset lingkungan, dekorasi, serta penanda lainnya dalam daftar.

Tiga kelompok pertama adalah aset yang paling sering dilihat pemain.
