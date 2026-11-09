# SHIFT MART — Rencana implementasi untuk Codex

Versi 1.0 · 6 November 2026 · Dokumen eksekusi, bukan implementasi game.

## 1. Mandat

Bangun party racing 3D kompetitif dengan trolley supermarket untuk 3–5 pemain manusia, Windows, keyboard, English UI. Satu pemain menjadi host. Tema: night shift, shifting gear, shifting route. Fokus: mengemudi yang mudah, sabotase, tabrakan lucu, dan rematch cepat. Tim 4–5 orang dengan kontribusi sekitar 3–5 jam per orang per hari. Aset final dibuat tim sendiri; primitive shapes untuk prototype.

Target internal: build siap unggah 30 November 2026. Anggap deadline resmi terpisah dan periksa kembali halaman jam sebelum submission. Jangan menggantungkan pengerjaan pada hari tambahan.

Dokumen ini memperbarui keputusan lama: target bukan LAN-only atau 2–4 pemain; trolley yang hancur diperbaiki di tempat selama lima detik, bukan respawn biasa. GDD lama tetap menjadi referensi ide; keputusan lebih baru dalam dokumen ini menjadi acuan implementasi.

## 2. Scope terkunci dan asumsi

### Dikonfirmasi pengguna

- Godot terbaru yang stabil; Windows only; anggaran nol.
- Host dari rumah salah satu pemain, teman bergabung dari rumah berbeda.
- Target 3–5 pemain. Solo dan dua pemain boleh untuk debug.
- Menang dengan menyelesaikan balapan; prioritas chaotic sabotage.
- Rider selalu menempel pada trolley, hanya visual.
- Trolley dan upgrade punya durability terpisah.
- Rusak: lima detik repair di lokasi, lalu mendapat upgrade.
- Lap berulang dan rute dapat berubah; hubungan lap dengan shift belum diputuskan.
- Satu supermarket low-poly, cartoon absurdity, atmosfer midnight, referensi keterbacaan Stumble Guys.
- Output akhir proyek: editable project, Windows build, panduan, source GitHub publik, materi itch.io.

### Asumsi sementara yang boleh diprototype tanpa menunggu

| ID | Keputusan awal | Status |
|---|---|---|
| A1 | Dua gear personal: Grip dan Rush | Belum disetujui final |
| A2 | Shift diterima mengubah gear pemohon dan menukar layout global A/B | Belum disetujui final |
| A3 | Warning 1,5 detik; cooldown global 6 detik | Nilai playtest |
| A4 | Lap tidak otomatis mengubah layout; shift tidak menambah lap | Interpretasi sementara |
| A5 | Gate mengalihkan jalur permanen; tidak memindahkan lantai atau rak | Untuk scope jam |
| A6 | Repair otomatis, invulnerable, satu upgrade mengganti yang lama | Belum disetujui final |
| A7 | Upgrade gratis dari tiga pilihan, default armor bila tidak memilih | Belum disetujui final |
| A8 | ENet direct IP; port forwarding diperlukan bila host tidak punya koneksi langsung | Baseline koneksi, bukan jaminan NAT traversal |

Sebelum memoles shifting, tunjukkan satu prototype junction dan minta keputusan A1–A5. Sebelum menambah tiga upgrade, tunjukkan repair plus satu upgrade untuk menilai A6–A7. Jangan mengimplementasikan tiga alternatif shifting sekaligus. Simpan pilihan sementara dalam docs/DECISIONS.md.

Jika pengguna tetap ingin perubahan setiap lap: alternatif paling kecil adalah layout global ditukar saat pemimpin menyelesaikan lap, memakai warning dan gate safety yang sama; gear hanya mengatur handling. Ini mengganti A2/A4, bukan menambah sistem lain. Konfirmasi dahulu karena mengubah premis gear mengubah rute.

## 3. Batas build jam

Wajib: host/join, lobby ready, 3–5 pemain, satu circuit, dua gear, dua konfigurasi gate, dua junction minimum, tiga lap, ramming, durability, repair lima detik, satu slot upgrade dengan durability, banana dan can, HUD, results, rematch, Windows export, petunjuk koneksi.

Target setelah wajib stabil: junction ketiga, total tiga pilihan upgrade, sound dan dressing lengkap.

Di luar scope: akun, matchmaking publik, lobby room-code dengan backend baru, dedicated server berbayar, host migration, reconnect ke race berjalan, AI racer, berjalan kaki, procedural map, realistic wheel physics, inventory kompleks, destructible shelves, voice chat, progression permanen, toko upgrade, split-screen, controller, mobile/browser.

Jangan mengurangi online menjadi LAN lalu menyatakan game selesai. Jika koneksi internet belum bekerja, laporkan sebagai blocker.

## 4. Stack dan batas teknis

- Godot 4.7.2 standard, GDScript typed. Halaman resmi diperiksa 6 November 2026; semua anggota memakai versi dan export templates yang sama. Jangan upgrade engine selama jam.
- Compatibility renderer, physics 60 Hz. Windows x86_64 sebagai export resmi.
- CharacterBody3D untuk trolley; gerakan arcade, visual roda/rider terpisah dari collision.
- ENetMultiplayerPeer untuk koneksi; satu listen server, maksimal empat remote peers plus host.
- Host menjadi sumber kebenaran untuk gerakan, benturan, damage, gate, pickup, lap, repair, upgrade, dan hasil.
- Tidak ada plugin wajib pada baseline. Jangan menambahkan framework besar atau backend sendiri.
- Git: main harus bisa dibuka; branch singkat per fitur. Hindari dua anggota mengedit scene yang sama.
- Jangan commit .godot/, export binaries, secrets, atau file sementara. Commit source assets dan .uid yang diperlukan. Lisensi source dan lisensi aset dibedakan; keputusan lisensi dicatat sebelum publikasi.

## 5. Koneksi internet: milestone yang harus dibuktikan pertama

Host memasukkan nama dan port UDP 24567. Client memasukkan nama, alamat host, dan port. UI menampilkan connecting, timeout, server full, version mismatch, host disconnected. Jangan membuat room code semu yang tidak bisa menjangkau internet.

ENet direct IP tidak otomatis melewati NAT/CGNAT. Uji dua rumah sejak hari pertama. Uji LAN bukan pengganti uji ini.

Urutan penanganan:
1. Buktikan dua proses lokal terhubung.
2. Buktikan dua mesin di LAN.
3. Uji direct IP dua rumah dengan UDP forwarding dan firewall host jika tersedia.
4. Jika CGNAT menghalangi, laporkan. Tawarkan penggunaan aplikasi virtual LAN gratis sebagai pilihan yang harus disetujui pengguna, dengan verifikasi ketentuan dan ketersediaan terkini. Jangan menjadikannya dependensi diam-diam.
5. Jika wajib koneksi seluruhnya di game pada jaringan tersebut, evaluasi relay/transport terkelola terlebih dahulu. Tetap nol biaya, cek batas layanan dan izin jam; jangan menjanjikan relay gratis tanpa verifikasi. Catat perubahan scope sebelum implementasi.

M0 belum lolos sampai dua orang dari rumah berbeda benar-benar masuk sesi yang sama. README harus menjelaskan metode koneksi yang akhirnya dipakai dan keterbatasannya.

## 6. Struktur proyek

```text
project.godot
export_presets.cfg
scenes/
  app.tscn
  ui/main_menu.tscn
  ui/lobby.tscn
  ui/hud.tscn
  ui/results.tscn
  race/race_world.tscn
  race/trolley.tscn
  race/junction.tscn
  race/checkpoint.tscn
  items/pickup_stand.tscn
  items/banana.tscn
  items/can.tscn
scripts/
  app.gd
  net/network_session.gd
  net/protocol.gd
  race/race_manager.gd
  race/trolley_controller.gd
  race/trolley_visual.gd
  race/damage_system.gd
  race/repair_system.gd
  race/shift_manager.gd
  race/junction_controller.gd
  race/checkpoint_manager.gd
  items/item_manager.gd
  items/pickup_stand.gd
  ui/hud.gd
resources/
  balance.tres
  trolley_tuning.gd
  item_definition.gd
  upgrade_definition.gd
assets/models/
assets/audio/
assets/materials/
docs/DECISIONS.md
docs/PROGRESS.md
docs/TEST_MATRIX.md
docs/ASSET_LIST.md
README.md
LICENSE
CREDITS.md
tests/
```

Ini struktur awal, bukan kewajiban membuat abstraction untuk setiap file. NetworkSession satu autoload; RaceManager hidup di race scene. Gabungkan modul kecil bila pemisahan hanya menambah boilerplate.

Scene trolley: CharacterBody3D, collision sederhana, VisualRoot, mesh trolley, rider, empat roda visual, camera pivot untuk pemain lokal. Camera tidak berada pada rig yang ikut wobble. RaceWorld: static geometry, start grid, checkpoints, junctions, pickups, RaceManager. Tidak ada simulasi jaringan untuk produk dekoratif.

## 7. Model jaringan yang harus konsisten

### Data

- Player: peer_id, display_name, ready, connected; identitas jaringan diikat sender RPC, bukan ID bebas dari client.
- Trolley: transform, planar_velocity, gear, health, held_item, upgrade_id, upgrade_health, status, repair_end_tick, protection_end_tick.
- Progress: completed_laps, expected_checkpoint, current_segment, finish_tick.
- Shift: layout_id, pending_player, execute_tick, cooldown_end_tick, revision.
- Race: session_id, phase, start_tick, finish_deadline, participants.
- Item: entity_id, type, owner, spawn_tick, expire_tick, active.

### Transport

- Channel 0 reliable: lobby, roster, scene readiness, race phase, hasil, shift event, repair/upgrade event, spawn/despawn.
- Channel 1 unreliable ordered: input commands, sequence meningkat.
- Channel 2 unreliable ordered: world snapshots, sequence meningkat; full small snapshot sekitar 20 Hz sebagai titik awal.
- Input dikirim sekitar 30 Hz: throttle, steer, brake, sequence. Clamp nilai dan abaikan sequence lama. Host tidak menerima posisi/damage/lap dari client.
- Request discrete item/shift/repair choice reliable dan divalidasi host. Gunakan event/command ID agar retransmisi tidak mengeksekusi dua kali.
- Host menjalankan physics untuk semua trolley. Client menginterpolasi visual snapshot; jangan menjalankan solver tabrakan otoritatif kedua.
- Awali tanpa prediction/reconciliation. Uji feel pada latency nyata sebelum menambahnya. Jika steering tidak layak, prioritaskan prediction trolley lokal menggunakan motor yang sama dan reconciliation ke host; jangan menambah rollback seluruh dunia.
- Snapshot juga membawa health/layout/item state agar packet event yang hilang tidak menghasilkan state permanen salah. Revision mencegah event lama menimpa state baru.
- Clock gameplay menggunakan tick host. UI menghitung countdown dari estimasi tick; tidak menentukan kapan damage/repair selesai.
- Host lokal melewati validator yang sama melalui function call; jangan menduplikasi jalur permainan khusus host.

### Siklus sesi

MENU → CONNECTING → LOBBY → LOADING → COUNTDOWN → RACING → FINISHING → RESULTS → LOBBY.

Ready seluruh peserta, minimal tiga dalam release; override debug untuk satu/dua. Setelah semua selesai loading, host menjadwalkan countdown. Timeout loading kembali ke lobby dengan pesan. Join baru hanya di lobby. Client keluar saat race: hapus trolley, lanjutkan bila masih ada peserta, sesuaikan kondisi selesai. Host keluar: semua kembali menu dengan alasan; tidak ada host migration. Gagal koneksi: bersihkan peer dan node lama sebelum retry. Rematch membuat session_id baru dan menghapus seluruh state race.

## 8. Driving, collision, damage

- W accelerate; A/D steer; S brake lalu reverse saat hampir berhenti; E request gear; Space item; hold R stuck recovery; 1/2/3 upgrade selection ketika repair; Esc menu lokal.
- Grip top speed awal 12 m/s; Rush 15 m/s. Steering dan grip Grip lebih kuat. Semua lintasan dapat dilalui dua gear.
- Steering berdasarkan kecepatan; reverse membalik respons dengan jelas. Hindari random input atau wobble fisik pada controller.
- CharacterBody tidak otomatis memberi tabrakan kendaraan yang menyenangkan. Host menghitung shove arcade antar pasangan trolley berdasarkan jarak/contact, relative approach speed dan arah normal.
- Tangani pasangan hanya sekali per tick dengan ID pasangan terurut. Dorongan diterapkan ke velocity eksternal yang meluruh, dibatasi agar tidak melempar trolley keluar map.
- Damage hanya saat relative impact melewati ambang; gentle contact tidak damage. Cooldown kontak pasangan dan satu detik damage protection mencegah damage setiap physics frame.
- Health 100; strong ram 15–25; can 15. Head-on merusak keduanya, rear/side mayoritas ke penerima. Wall collision damage berdasarkan impact sebelum penyelesaian gerak.
- Host menentukan hit dan pickup. Client mengirim niat, bukan hasil.
- Jangan membuat bent wheel memengaruhi steering acak. Efek health rendah cukup visual/audio dulu.

## 9. Shift dan gate safety

READY → WARNING → COOLDOWN → READY.

1. Host menerima request ketika phase race aktif dan trolley dapat beraksi.
2. Valid request pertama pada urutan host dipilih; request lain ditolak, tidak diantrekan.
3. Broadcast requester, target layout, execute_tick (1,5 detik mendatang).
4. Pada execute_tick, gear requester ditukar jika masih peserta; jika trolley repair, gear tetap dapat diubah tetapi tidak bergerak sampai repair selesai. Global shift tetap terjadi jika requester rusak/disconnect.
5. Layout revision bertambah; cooldown enam detik dimulai. Semua gear client mengikuti state host.

Gate mengontrol entrance dua branch yang sudah ada. Exits selalu terbuka. Mobil yang sudah masuk dapat menyelesaikan branch lama. Tidak ada teleport ke route baru.

Saat gate perlu menutup dan safety volume terisi: stop entry baru dengan warning visual; tunggu volume bersih sebelum solid barrier ditutup. Setelah tiga detik terhalang, batalkan penutupan gate itu untuk revision tersebut; biarkan kedua branch valid sampai shift berikutnya. Jangan menghimpit/merusak trolley atau menunggu selamanya. UI membedakan layout target dari gate yang masih pending. Semua branch melewati merge checkpoint yang sama, sehingga fallback tidak memberi lap gratis.

Pakai dua junction dahulu. Layout A/B mengubah gate state; lantai, rak dan checkpoints tidak dipindah. Checkpoint graph sama pada kedua layout. Warning pakai teks, simbol dan warna.

## 10. Repair dan upgrade

ACTIVE → REPAIRING (5 detik) → PROTECTED (2 detik) → ACTIVE.

- Health nol: velocity nol, item aktif dibatalkan, trolley menjadi ghost terhadap trolley lain dan tidak bisa menyerang/mengambil item/meminta shift.
- Environment collision tetap ada agar tidak jatuh menembus lantai. Pada jalur normal, repair di posisi saat rusak; straighten orientation pada awal repair.
- Tampilkan countdown dan pilihan upgrade. Satu slot, pilihan mengganti upgrade lama. Bila belum memilih saat waktu habis: armor. Pilihan dapat diklik/1–3; host hanya menerima pilihan ketika repair.
- Repair selesai: health 100, upgrade baru durability penuh. Protection dua detik; selama protected tidak memberi damage atau shove ke lawan.
- Jika posisi invalid/out-of-bounds: nearest safe anchor pada segment yang sudah dicapai; tidak boleh melewati checkpoint berikutnya. Ini recovery darurat, bukan respawn normal.
- Hold R 2 detik memulai recovery lima detik ke safe anchor tanpa memberi upgrade baru. Ini mencegah tombol reset menjadi cara farming upgrade.

Upgrade target:
| Upgrade | Efek awal | Pengurangan durability |
|---|---|---|
| Cardboard armor | Menyerap damage ke upgrade lebih dahulu | Sejumlah damage yang diserap; sisa mengenai body |
| Spring bumper | Shove ram keluar +25%; damage body tidak bertambah | 20 per eligible offensive ram |
| Grippy wheels | Grip +15%; tidak memberi top speed tambahan | 1 per detik mengemudi aktif |

Durability awal masing-masing 100; nol menghapus efek. Tidak ada stacking, loot rarity, atau upgrade permanen. Implementasi pertama hanya armor; dua lainnya sesudah full race stabil. Uji apakah sengaja menghancurkan trolley menguntungkan: jika iya, kurangi kekuatan upgrade, jangan tambah ekonomi baru.

## 11. Items

Satu slot, pickup stand tetap dengan item yang terlihat, refill delapan detik. Tidak overwrite inventory penuh. Bila beberapa pemain mengambil bersamaan, host memberikan ke satu pemain saja.

- Banana: drop di belakang, tidak mengenai pemilik selama 0,5 detik; setelah itu bisa mengenai siapa pun. Slip sekitar 0,8 detik, tidak mematikan kontrol sepenuhnya. Satu hit atau delapan detik lalu hilang.
- Can: forward projectile, hit pertama damage 15 dan shove kecil; timeout empat detik. Grace owner singkat agar tidak menabrak diri saat spawn; kemudian friendly/self hit boleh. Host memakai swept query/raycast sepanjang perjalanan agar tidak menembus objek pada speed tinggi.
- Cap awal delapan banana dan delapan can aktif per sesi; jika penuh tolak penggunaan tanpa menghabiskan item. Broadcast spawn/despawn dengan entity_id unik.
- Flour, detergent, boost, homing, trap tambahan masuk parking lot; tidak dibuat pada jam baseline.

## 12. Track, lap, dan ranking

Satu circuit, tiga lap, target match 3–5 menit, hard limit lima menit. First finisher memulai countdown 20 detik; selesai saat semua selesai atau batas waktu tercapai.

Ordered checkpoint Areas, validasi arah dan expected checkpoint pada host. Finish line tidak dihitung saat spawn. Crossing line hanya menyelesaikan lap jika semua checkpoint dilewati. Reverse line, shortcut melalui gate, reset, repair, dan perubahan layout tidak boleh menambah progress.

Branch A/B punya segment progress 0..1 yang dipetakan ke interval ranking bersama hingga merge; jangan membandingkan jarak Euclidean ke finish. Ranking: finisher berdasarkan finish tick, kemudian completed laps, segment index, progress. Tie-break stabil peer_id. DNF ditandai saat timeout; disconnected dicatat terpisah.

Buat safe anchors per segment. Gate dan palette membedakan route; signage tetap terbaca saat low graphics. Lebar mayoritas dua trolley, bottleneck pendek. Beri jarak warning yang cukup sebelum junction dan ruang recovery setelah tikungan.

## 13. UI, art, audio, performance

UI: host/join, nama, IP/port, ready list, count/max players, start host, errors, countdown, position/lap, gear, body/upgrade durability, item, shift availability, layout warning/requester, repair pilihan, results, rematch. Semua teks game English. Esc tidak mem-pause sesi online.

Aset final minimum: trolley satu model dan varian warna lima pemain; rider satu; rak, freezer, checkout, pallet, gate; tiga product props; banana/can; pickup marker; arrows. Gunakan .glb, meter scale, floor Y=0; forward convention ditulis di ASSET_LIST. Collision authored sederhana terpisah dari mesh detail. Rig boleh diganti selama node contract tetap.

Audio minimum: motor/roda loop, ram, break, repair, warning, gate, pickup, item, finish; volume master dan mute. Tidak perlu voice acting.

Laptop baseline Ryzen 3 7320U: target minimal 30 FPS stabil 720p low pada host lima pemain, aspirasi 60 FPS. Ukur pada mesin nyata; jangan mengklaim berdasarkan headless test. Baked/simple lighting, shadow terbatas, tanpa GI real-time, tanpa physics groceries. Profil frame time, active objects, bandwidth, dan host CPU sebelum optimasi kompleks.

## 14. Milestone dan acceptance gate

| ID / tanggal target | Pekerjaan Codex | Bukti selesai |
|---|---|---|
| M0 · 6–8 Nov | Scaffold, version lock, menu host/join, lobby, primitive trolley | Dua rumah terhubung; retry dan disconnect bersih; catat jalur koneksi |
| M1 · 9–11 Nov | Host simulation, input/snapshot, camera, collision | Lima pemain mengemudi bersama; host/client dapat ram konsisten |
| M2 · 12–14 Nov | Satu junction, dua gear, warning/cooldown/gate safety | Simultaneous requests satu pemenang; occupied gate aman; pengguna menilai aturan shift |
| M3 · 15–18 Nov | Circuit dua junction, lap/rank, damage, repair, armor | Satu match lengkap berakhir; repair di tempat; rematch tidak menyimpan state lama |
| M4 · 19–22 Nov | Banana/can, dua upgrade lain jika stabil | Pickup tidak dobel; projectile konsisten; lima pemain memainkan beberapa race |
| M5 · 23–25 Nov | Aset/audio/HUD final, performance, junction ketiga bila sempat | Laptop baseline mencapai target; placeholder utama terganti |
| M6 · 26–27 Nov | Bugfix multiplayer, Windows export, docs | Build fresh download dapat host/join dari dua rumah |
| Freeze · 28–30 Nov | Hanya bugfix penting; screenshots, itch copy, repo source | Release candidate, halaman submission dan checklist siap |

Jika milestone molor, kurangi konten berikutnya. Jangan menandai tanggal sebagai bukti selesai. Prioritas potongan: junction ketiga → efek kosmetik → dua upgrade tambahan → can → banana. Pertahankan online lima pemain, gear/rute, ramming, repair, satu upgrade, complete race. Setiap pemotongan requirement wajib dilaporkan, bukan disembunyikan.

## 15. Pembagian tim

- Programmer/network owner: protocol, trolley authority, integrasi, export. Satu pemilik utama mengubah netcode.
- Gameplay/level: checkpoints, junction, items, graybox track; scene ownership jelas.
- 3D artist: trolley/rider/store modular props, import contract, materials.
- UI/audio/QA: HUD, sound, test lintas rumah, itch material.
- Anggota kelima bila ada: QA/release dan bantuan art. Jika empat, gabungkan peran terakhir.

Codex boleh mengerjakan source dan dokumentasi; manusia menjalankan tes teman/laptop dan memasok aset. Jangan membuat klaim tes multiplayer manusia yang belum dijalankan. Tiap hari integrasikan build pendek; jangan menunggu semua aset jadi.

## 16. Tes yang bermakna

Automated/headless bila tersedia:
- Scene import dan parse seluruh script; jalankan startup tanpa error.
- Pure state tests: shift serialization/cooldown, item ownership sekali, damage cooldown, upgrade overflow, repair exact tick, lap checkpoint ordering, results tie-break, rematch reset.
- Multi-process integration: host + clients, ready/start, disconnect, replicated layout/health, no stale entities after rematch.

Manual wajib:
| Skenario | Harapan |
|---|---|
| Lima pemain dari beberapa rumah | Roster benar; race dan hasil sama |
| Dua orang shift pada saat berdekatan | Satu accepted; gear/layout/cooldown konsisten |
| Trolley di gate atau branch lama | Tidak terjepit dan masih dapat keluar |
| Rusak dekat gate, terbalik, di luar map | Repair aman; tidak melewati checkpoint |
| Dua pemain mengambil stand sama | Tepat satu inventory mendapat item |
| Repeat wall/contact ram | Tidak kena damage setiap frame |
| Mundur finish atau skip checkpoint | Tidak menambah lap |
| Client keluar saat repair/shift/finish | Sesi lanjut tanpa node yatim |
| Host keluar | Client menerima pesan dan kembali menu |
| Tiga rematch berturut-turut | Tidak ada item, timer, rank atau peer state lama |
| Delay sekitar 100–200 ms dan loss ringan jika alat tersedia | Kontrol masih layak; state akhirnya konsisten |
| Export di Windows yang tidak membuka editor | Menu, assets, audio dan koneksi berjalan |

Catat tanggal, versi build/commit, jumlah pemain, host hardware, jalur koneksi, hasil dan known issues. Pengujian yang belum berjalan ditulis NOT RUN.

## 17. Prosedur kerja Codex

1. Baca AGENTS.md aktual, dokumen ini, DECISIONS dan PROGRESS. Periksa repo dan tool Godot yang benar-benar tersedia.
2. Jika repo kosong, scaffold M0. Jika sudah ada proyek, audit sebelum mengubah; jangan overwrite pekerjaan orang.
3. Kerjakan satu milestone sampai executable dan terverifikasi. Buat checkpoint commit jika workflow repo mengizinkan; jangan push/publish tanpa otorisasi yang sesuai.
4. Gunakan placeholder lokal sederhana, jangan mencari/beli aset sebagai prasyarat.
5. Simpan balancing di resource, jangan sebar magic number di script.
6. Jangan mengimplementasikan stretch sebelum acceptance gate wajib lewat.
7. Jalankan import/parse dan test relevan setelah perubahan. Jika executable Godot atau Windows export template tidak tersedia, catat blocker dan lanjutkan bagian yang bisa diperiksa; jangan menyebut build tested.
8. Update PROGRESS dengan completed/current/next, bukti tes, assumptions, blockers. Update DECISIONS hanya jika ada keputusan baru, tandai siapa yang menyetujui.
9. Di akhir setiap milestone laporkan perilaku yang jadi, cara menjalankan, test aktual, batasan, dan langkah berikutnya. Jangan berhenti hanya setelah menulis stub atau TODO.
10. Jika koneksi jaringan terhalang environment Codex, buat paket instruksi tes manusia yang konkret; bedakan environment blocker dari bug game.

Tidak perlu service locator, custom ECS, event bus universal, generic inventory framework, procedural track generator, atau test yang hanya memeriksa nilai konstanta. Kode sederhana dengan ownership jelas lebih penting.

## 18. Release dan publikasi

- Export Windows x86_64; ZIP berisi exe + pck bila terpisah, README koneksi/controls dan licenses.
- Source repo publik berisi project, aset yang boleh didistribusikan, build instructions dengan versi engine, credits dan keputusan lisensi. Tidak ada token/private IP logs/rahasia.
- Siapkan judul, pitch singkat, controls, player count, cara host/join dan prasyarat koneksi, screenshots gameplay, known issues, serta tautan source.
- Tes fresh extraction di lokasi baru; jangan mengandalkan file absolut di komputer developer.
- Periksa aturan AI/premade assets, source, dan deadline di halaman jam saat release; catat penggunaan bantuan sesuai aturan. Jangan menyatakan patuh hanya karena memakai engine tertentu.
- Codex menyiapkan file dan draft halaman. Publikasi/upload/submission dilakukan sesuai otorisasi pengguna pada tahap tersebut; tidak perlu akun/backend baru untuk menulis game lokal.

Definition of done: 3–5 teman dari rumah berbeda dapat connect dengan metode terdokumentasi, race tiga lap dengan route shifting dan sabotase, repair lima detik, menerima hasil konsisten, lalu rematch; Windows build dapat dibuka bersih, source dan petunjuk tersedia. Yang belum teruji tetap dicatat sebagai batasan.

## 19. Prompt awal untuk ditempel ke Codex

> Baca SHIFT_MART_CODEX_PLAN.md dan AGENTS.md. Implementasikan SHIFT MART bertahap sesuai scope dan acceptance gates. Mulai audit workspace lalu kerjakan M0; jangan hanya membuat rencana baru. Gunakan Godot 4.7.2 standard/GDScript dan Compatibility renderer. Buat source project, primitive trolley, host/join, lobby dan jalur koneksi ENet yang terdokumentasi. Perlakukan keputusan A1–A8 sebagai asumsi sementara, bukan persetujuan final. Jangan menjanjikan direct-IP bisa melewati CGNAT. Verifikasi dengan tools yang tersedia, catat tes yang belum dapat dijalankan, dan tulis docs/PROGRESS.md agar sesi berikutnya dapat melanjutkan. Setelah M0 terbukti atau ada blocker eksternal konkret, laporkan bukti dan lanjutkan bagian independen yang aman. Jangan menambah stretch feature.

## 20. Referensi teknis

Diperiksa 6 November 2026. Angka gameplay dan arsitektur di atas adalah rekomendasi proyek, bukan klaim dokumentasi engine.

- Godot Windows/version: https://godotengine.org/download/windows/
- Godot high-level multiplayer, ENet, RPC dan koneksi internet: https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
- Aturan dan jadwal jam: https://itch.io/jam/game-off-2026
