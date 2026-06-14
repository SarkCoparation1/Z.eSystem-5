[org 0x1000]
[bits 32]


kernel_main:
	call temizle_32
	mov byte [son_basilan_tus], 0
	
	mov edi, 0xB8000
	mov esi, baslik
	mov ah, 0x1F
	call yazdir_32
	
	mov edi, 0xB80A0
	mov esi, buton_metni1
	mov ah, 0x6F
	call buton_32
	
	mov edi, 0xB8140
	mov esi, buton_metni2
	mov ah, 0x7F
	call buton_32
	
	mov edi, 0xB81E0
	mov esi, buton_metni3
	mov ah, 0x9F
	call buton_32
	
	mov edi, 0xB8280
	mov esi, buton_metni4
	mov ah, 0x3F
	call buton_32
	
	mov edi, 0xB8320
	mov esi, buton_metni5
	mov ah, 0xBF
	call buton_32
	
	call idt_kur
	
.tus_dongusu:
	call bekle_32
	
	cmp al, 0x02
	je .b1
	
	cmp al, 0x03
	je .b2
	
	cmp al, 0x04
	je .b3
	
	cmp al, 0x05
	je .b4
	
	cmp al, 0x06
	je .b5
	
	call temizle_32
	
	mov esi, bilinmiyor
	mov edi, 0xB8000
	mov ah, 0x1E
	call yazdir_32
	
	add edi, 160
	mov esi, cikis_tusu
	call yazdir_32
	
	call bekle_32_h
	
	jmp kernel_main

.b1:
	call temizle_32
	
	mov esi, ver
	mov edi, 0xB8000
	mov ah, 0x1F
	call yazdir_32
	
	add edi, 160
	mov esi, cikis_tusu
	call yazdir_32
	
	call bekle_32_h
	
	jmp kernel_main
	

.b2:
	call temizle_32
	
	mov esi, haber1
	mov edi, 0xB8000
	mov ah, 0x1F
	call yazdir_32
	
	add edi, 160
	mov esi, cikis_tusu
	call yazdir_32
	
	call bekle_32_h
	jmp kernel_main
	
.b3:
	call temizle_32
	mov edx, kernel_api_table
	mov esi, 0x2200
	call calistir_launchable
	jmp kernel_main
	
.b4:
	call temizle_32
	mov edx, kernel_api_table
	mov esi, 0x2400
	call calistir_launchable
	jmp kernel_main
	
.b5:
	call temizle_32
	
	mov edi, 0xB8000
	mov esi, kapatma_mesaji
	mov ah, 0x1F
	call yazdir_32
	
	jmp sistem_halt


yazdir_32:
	pusha
.yazdirma_dongusu:
	lodsb
	or al, al
	jz .yazdirma_bitti
	mov [edi], al
	mov [edi + 1], ah
	add edi, 2
	jmp .yazdirma_dongusu
.yazdirma_bitti:
	popa
	ret
	
temizle_32:
	pusha
	mov edi, 0xB8000
	mov ecx, 80 * 25
.temizle_dongusu:
	mov [edi], byte ' '
	mov [edi + 1], byte 0x1F
	add edi, 2
	loop .temizle_dongusu
	popa
	ret
	
buton_32:
	pusha
	mov ebx, edi
	mov ecx, 30
.zemin_dongusu:
	mov [edi], byte ' '
	mov [edi + 1], ah
	add edi, 2
	loop .zemin_dongusu
	add ebx, 4
	mov edi, ebx
.metin_dongusu:
	lodsb
	or al, al
	jz .buton_bitti
	mov [edi], al
	mov [edi + 1], ah
	add edi, 2
	jmp .metin_dongusu
.buton_bitti:
	popa
	ret
	
bekle_32:
	push ecx
.bekleme_dongusu:
	mov al, [son_basilan_tus]
	cmp al, 0
	je .bekleme_dongusu
	
	mov byte [son_basilan_tus], 0
	pop ecx
	ret
	
bekle_32_h:
	push eax
.h_bekleme_dongusu:
	mov al, [son_basilan_tus]
	cmp al, 0
	je .h_bekleme_dongusu
	
	mov byte [son_basilan_tus], 0
	pop eax
	ret
	
calistir_launchable:
	pusha
	
	cmp byte [esi], 0x4C
	jne .hatali_dosya
	cmp byte [esi + 1], 0x4E
	jne .hatali_dosya
	cmp byte [esi + 2], 0x43
	jne .hatali_dosya
	
	cmp byte [esi + 3], 0x02
	jne .hatali_dosya
	
	mov ebp, esi
	
	mov eax, [esi + 4]
	add eax, esi
	
	call eax
	
	popa
	ret
	
.hatali_dosya:
	popa

	call temizle_32
	
	mov esi, bilinmiyor2
	mov edi, 0xB8000
	mov ah, 0x1F
	call yazdir_32
	
	add edi, 160
	mov esi, cikis_tusu
	call yazdir_32
	
	call bekle_32_h
	
	ret
	
sistem_halt:
	cli
	hlt
	jmp sistem_halt
	
baslik: db "===== Z.eSystem =====", 0
buton_metni1: db "[1] Z.eSystem surumu", 0
buton_metni2: db "[2] Haberler", 0
buton_metni3: db "[3] ornek.launchable", 0
buton_metni4: db "[4] devkit.launchable", 0
buton_metni5: db "[5] Kapat", 0
ver: db "Z.eSystem 5", 0
cikis_tusu: db "Cikmak icin herhangi bir tusa basin...", 0
bilinmiyor: db "Bilinmeyen komut!", 0
bilinmiyor2: db "Gecersiz .launchable dosyasi!", 0
haber1: db "Z.eSystem artik gercek isletim sistemine donustu!", 0
kapatma_mesaji: db "Bu bilgisayari guvenle kapatabilirsiniz", 0

kernel_api_table:
	dd yazdir_32
	dd temizle_32
	dd bekle_32
	dd son_basilan_tus

%include "idt.asm"

times 4608-($-$$) db 0