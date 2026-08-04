"""Bikin ikon peluncur persegi dari wordmark JNE.

Wordmark aslinya sangat melebar (rasio ~2.4:1). Dulu dia dijejalkan apa adanya
ke kanvas persegi, jadi di layar HP tulisannya kecil dan sisanya putih kosong.

Di sini wordmark dipangkas ke piksel non-putih, diskalakan ke lebar yang lega,
lalu ditaruh di tengah kanvas putih bersih. Ukuran wordmark dijaga di dalam
"safe zone" ikon adaptif Android (66% bagian tengah) supaya tidak terpotong
saat diberi mask bulat/rounded oleh launcher.

Jalankan: python tool/make_icon.py
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'assets' / 'images' / 'app_icon.png'
OUT = ROOT / 'assets' / 'images' / 'app_icon_square.png'

CANVAS = 1024
# Lebar wordmark relatif kanvas. Ikonnya legacy (tidak ada mipmap-anydpi-v26),
# jadi launcher cuma memberi rounded corner tipis — wordmark boleh lebar supaya
# terbaca di grid home screen. Sisakan sedikit margin agar huruf tepi tak nempel.
WORDMARK_WIDTH_RATIO = 0.84
BACKGROUND = (255, 255, 255, 255)


def trim_to_content(img: Image.Image) -> Image.Image:
    """Buang bingkai kosong (transparan atau putih) di sekeliling logo."""
    rgba = img.convert('RGBA')
    alpha = rgba.getchannel('A')
    box = alpha.getbbox() if alpha.getextrema()[0] < 255 else None
    if box is None:
        # Tidak ada transparansi — cari area yang bukan putih.
        grey = rgba.convert('L')
        mask = grey.point(lambda p: 255 if p < 245 else 0)
        box = mask.getbbox()
    return rgba.crop(box) if box else rgba


def main() -> None:
    logo = trim_to_content(Image.open(SRC))

    target_w = round(CANVAS * WORDMARK_WIDTH_RATIO)
    target_h = round(logo.height * target_w / logo.width)
    logo = logo.resize((target_w, target_h), Image.LANCZOS)

    canvas = Image.new('RGBA', (CANVAS, CANVAS), BACKGROUND)
    canvas.alpha_composite(logo, ((CANVAS - target_w) // 2, (CANVAS - target_h) // 2))
    canvas.save(OUT)
    print(f'wrote {OUT} ({CANVAS}x{CANVAS}, wordmark {target_w}x{target_h})')


if __name__ == '__main__':
    main()
