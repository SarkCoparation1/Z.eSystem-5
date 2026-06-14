[org 0x0]                           ; Göreceli (EBP) ofset hesaplama
[bits 32]

; --- LNC v2 Başlığı ---
db 0x4C, 0x4E, 0x43                 ; "LNC" İmzası
db 0x02                             ; Versiyon
dd devkit_basla - $$                ; Giriş noktası ofseti

devkit_basla:
	; Komut tamponunu ve sayaçları sıfırla
	mov ecx, 64
	mov edi, ebp
	add edi, komut_tamponu
.tampon_temizle:
	mov byte [edi], 0
	inc edi
	loop .tampon_temizle

	mov dword [ebp + tampon_indeksi], 0

	; Çekirdek API'lerini al
	mov eax, [edx + 4]              ; temizle_32
	call eax                        ; Ekranı temizle

	; Başlık Mesajını Bas
	mov edi, 0xB8000
	mov esi, ebp
	add esi, dev_baslik
	mov ah, 0x0E                    ; Siyah zemin, Sarı yazı
	mov ecx, [edx + 0]              ; yazdir_32
	call ecx

	; Komut İstemi (Prompt "> ") Çiz
	mov edi, 0xB80A0
	mov esi, ebp
	add esi, prompt
	call ecx

	mov ebx, 0xB80A4                ; Yazının ekrandaki başlangıç video belleği

.komut_dongusu:
	mov ecx, [edx + 12]             ; son_basilan_tus adresini al
.tus_bekle:
	mov al, [ecx]
	cmp al, 0
	je .tus_bekle
	
	mov byte [ecx], 0               ; Tuşu tüket

	cmp al, 0x01                    ; ESC tuşuna basılırsa çık ve Kernel'e dön
	je .dev_cikis

	cmp al, 0x1C                    ; ENTER tuşuna basılırsa komutu işlet
	je .komut_isle

	; Basılan tuşu harfe dönüştür
	call klavye_ascii_cevir
	or al, al
	jz .komut_dongusu               ; Bilinmeyen karakterse yoksay

	; Harfi komut tamponuna kaydet
	mov esi, [ebp + tampon_indeksi]
	cmp esi, 60                     ; Sınır kontrolü
	jge .komut_dongusu
	
	mov [ebp + komut_tamponu + esi], al
	inc dword [ebp + tampon_indeksi]

	; Ekrana bas
	mov [ebx], al
	mov [ebx + 1], byte 0x0F        ; Beyaz renk
	add ebx, 2
	jmp .komut_dongusu

.komut_isle:
	; --- DİNAMİK KOMUT YORUMLAYICI (PARSER) ---
	cmp byte [ebp + komut_tamponu], 'Y'
	jne .bilinmeyen_komut
	cmp byte [ebp + komut_tamponu + 1], 'A'
	jne .bilinmeyen_komut
	cmp byte [ebp + komut_tamponu + 2], 'Z'
	jne .bilinmeyen_komut
	cmp byte [ebp + komut_tamponu + 3], ' '
	jne .bilinmeyen_komut

	mov edi, 0xB8140                ; Çıktının basılacağı alt satır adresi
	
	mov esi, ebp
	add esi, komut_tamponu
	add esi, 4                      ; "YAZ " ifadesini atla
	
	mov ah, 0x0A                    ; Çıktı rengi Yeşil
	mov ecx, [edx + 0]              ; yazdir_32
	call ecx
	jmp .konsolu_sifirla

.bilinmeyen_komut:
	mov edi, 0xB8140
	mov esi, ebp
	add esi, hata_mesaj
	mov ah, 0x0C                    ; Kırmızı renk
	mov ecx, [edx + 0]
	call ecx

.konsolu_sifirla:
	mov dword [ebp + tampon_indeksi], 0
	mov ecx, 64
	mov edi, ebp
	add edi, komut_tamponu
.tur_temizle:
	mov byte [edi], 0
	inc edi
	loop .tur_temizle

	mov edi, 0xB81E0                ; Yeni prompt satırı
	mov esi, ebp
	add esi, prompt
	mov ecx, [edx + 0]
	call ecx
	mov ebx, 0xB81E4                ; Klavyeyi yeni satıra odakla
	jmp .komut_dongusu

.dev_cikis:
	ret

; --- Düzeltilmiş Kararlı Klavye Fonksiyonu ---
klavye_ascii_cevir:
	cmp al, 0x15
	je .h_y
	cmp al, 0x1E
	je .h_a
	cmp al, 0x2C
	je .h_z
	cmp al, 0x32
	je .h_m
	cmp al, 0x30
	je .h_b
	cmp al, 0x39
	je .h_bosluk
	mov al, 0
	ret

.h_y:
	mov al, 'Y'
	ret
.h_a:
	mov al, 'A'
	ret
.h_z:
	mov al, 'Z'
	ret
.h_m:
	mov al, 'M'
	ret
.h_b:
	mov al, 'B'
	ret
.h_bosluk:
	mov al, ' '
	ret

; --- VERİ ALANI ---
dev_baslik:          db "=== Z.eSystem Developer Tool Suite v1.2 ===", 0
prompt:              db "> ", 0
hata_mesaj:          db "[Hata]: Gecersiz komut dizilimi!", 0

align 4
tampon_indeksi:      dd 0

align 4
komut_tamponu:       times 64 db 0

; Dosyayı 10 sektöre tamamlıyoruz
times 4608-($-$$) db 0