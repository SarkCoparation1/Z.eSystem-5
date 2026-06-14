[org 0x0000]
[bits 32]

; --- LNC v2 BAŞLIĞI (Tam Veri Hizalamalı - Toplam 16 Bayt) ---
db "LNC", 0x02              ; 1-4. Baytlar: İmza ve Versiyon
dd uygulama_baslangici     ; 5-8. Baytlar: Giriş noktasının dosya içindeki ofseti (Değeri: 16)
dd program_boyutu          ; 9-12. Baytlar: Programın toplam boyutu
dd stack_boyutu            ; 13-16. Baytlar: Ayrılacak Stack boyutu

program_baslangic:
uygulama_baslangici:
	pusha                   ; Çekirdeğin tüm register'larını koru

	; Ekrana yazı basacağımız video belleği konumu (2. satır başı)
	mov edi, 0xB8000 + 160
	
	; Dinamik adresleme (Relocation)
	mov esi, uygulama_mesaji
	add esi, ebp            ; Kernel'in EBP ile verdiği yükleme adresini ekliyoruz
	
	mov ah, 0x1F            ; Mavi arka plan, Beyaz yazı
.yazdirma_dongusu:
	lodsb
	or al, al
	jz .yazdirma_bitti
	mov [edi], al
	mov [edi + 1], ah
	add edi, 2
	jmp .yazdirma_dongusu

.yazdirma_bitti:
	; --- GÜNCELLENEN KLAVYE BEKLEME DÖNGÜSÜ ---
	; Çekirdekteki (kernel.asm/idt.asm içindeki) son_basilan_tus değişkenini kontrol ediyoruz.
	; kernel.asm 0x1000 adresinde başlar. idt.asm de onun içinde yer alır.
	; Çekirdeğin son_basilan_tus etiketinin tam adresini bulup buraya yazacağız veya 
	; en temizi, uygulama sadece bir süre döngüde dönüp kernel'e ret yapacak.
	
.bekle:
	; IDT arka planda çalışırken uygulamanın kilitlenmesini önlemek için 
	; doğrudan port okumak yerine basitçe bir tuşa basılmasını bekleyen çekirdek rutinini kullanabilirsin.
	; Şimdilik uygulamanın kilitlenmesini önlemek için port okumayı pasif yapıp
	; sadece test amaçlı döngü koyabiliriz ya da direkt ret ile çekirdeğe dönebiliriz.
	
	in al, 0x64
	and al, 0x01
	jz .bekle
	in al, 0x60
	test al, 0x80
	jnz .bekle

	popa                    ; Çekirdeğin register'larını geri yükle
	ret                     ; Çekirdeğe güvenle geri dön

uygulama_mesaji: db "Z.eSystem: Bu uygulama RAM'de her yerde calisir!", 0

; --- Dosya Sonu Hesaplamaları ---
program_boyutu equ $ - $$
stack_boyutu   equ 4096

; --- SEKTÖR SEVİYESİNDE DOLGU (Padding) ---
; Dosya boyutunu tam olarak 5120 bayta (10 sektöre) tamamlar.
times 512-($-$$) db 0