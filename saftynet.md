Safety Net — Backup Tags
Kalau ada masalah, bisa rollback:


# Parent rollback (KALAU PERLU, BIASANYA TIDAK):
cd C:\Users\USER\jne_attandance
git reset --hard backup-before-claude-strip-parent

# Admin rollback:
cd C:\Users\USER\jne_attandance\admin
git reset --hard backup-before-claude-strip-admin
Hapus backup tags kalau yakin gak butuh (nanti):


git -C C:\Users\USER\jne_attandance tag -d backup-before-claude-strip-parent
git -C C:\Users\USER\jne_attandance\admin tag -d backup-before-claude-strip-admin
⚠ PENTING: Force-Push Wajib untuk Sync ke GitHub
Karena SEMUA SHA berubah, local branch beda total dengan remote. Force-push wajib (bukan regular push).

Parent Repo

cd C:\Users\USER\jne_attandance
git push --force-with-lease origin main
Admin Repo

cd C:\Users\USER\jne_attandance\admin
git push --force-with-lease origin main
--force-with-lease lebih aman daripada --force — kalau ada orang lain yang sudah push ke remote sejak local kamu pull terakhir, command ini akan fail (mencegah overwrite kerjaan orang lain).

⚠ Jangan push kalau ada collaborator lain yang pakai repo ini — mereka harus delete branch local + clone ulang setelah force push.

📋 Uncommitted Changes (Belum di-Commit, Tidak Hilang)
Stash di-pop balik. Kerjaan kamu yg masih dirty:

Parent repo:

user_mobile/lib/screen/welcome/welcome_page.dart (formatted by IDE)
docs/ (3 file presentasi)
ada/ (folder accidental, bisa di-rm)
.kilo/kilo.json (deleted)
Admin repo:

4 placeholder pages dihapus (couriers, packages, sales, salary)
firestore.rules update delete permission
NotificationPanel.tsx + context update (icon smart + delete capability)
login-issues/page.tsx + delete button
chat/page.tsx (4 icon dihapus)
settings/page.tsx (theme-aware bg)
firestore.ts (deleteNotification methods)
2 hook files
Semua aman, gak hilang. Tinggal commit kalau mau.





Latest Commits (Verified Bersih)
Parent Repo

ff578d0  docs: project plan + user flows + presentation deck
cc2b5fd  feat(mobile): Play-Store-ready signing + first-login password + lapor admin
b24a36d  feat: audit fixes (crash + race + timezone + perf) + dark-mode systemic
Admin Repo

73c56c3  feat: notif panel improvements + chat header cleanup + delete capabilities
ab2b07e  feat(admin): WA onboarding + email auto via Resend + login issues + fixed sidebar
aebdce3  feat: admin updates + edit-requests page + index for mobile dispute/overtime
✅ Zero Co-Authored-By: Claude di SEMUA commit (verified earlier dengan grep)

Working Tree State
Repo	Status
Parent	✅ Clean (cuma admin submodule pointer modified — normal)
Admin	✅ Clean working tree
⚠ Reminder: Force Push untuk Sync ke GitHub
Karena history di-rewrite, SHA berubah. Untuk push ke remote:


# Parent
cd C:\Users\USER\jne_attandance
git push --force-with-lease origin main

# Admin
cd C:\Users\USER\jne_attandance\admin
git push --force-with-lease origin main
⚠ Cek GitHub repo settings dulu:

Pastikan branch main tidak protected (Settings → Branches → kalau ada rule "Require force-push approval", disable dulu)
Setelah push, re-enable kalau perlu