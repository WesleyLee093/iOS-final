# StudySnap (SwiftUI + MVVM)

本專案可在 Xcode 26 直接 Build & Run。支援本地 OCR、摘要/關鍵字/重點產生、題庫生成，以及透過 Supabase REST API（Auth + CRUD）同步筆記與題庫。

## 開發環境
- Xcode 26 / iOS 18 模擬器或實機（相機/相簿權限已於 Info 設定）
- SwiftUI + async/await

## Supabase 設定
1. 建立專案後，於 SQL Editor 執行下列指令建立資料表與 RLS：
```sql
-- notes
create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text,
  source_type text,
  raw_text text,
  summary text,
  key_points jsonb,
  keywords jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- quizzes（questions 以 JSONB 儲存）
create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  note_id uuid references public.notes(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  questions jsonb,
  created_at timestamptz default now()
);

alter table public.notes enable row level security;
alter table public.quizzes enable row level security;

-- 僅允許本人讀寫
create policy "notes_select_own" on public.notes for select using (auth.uid() = user_id);
create policy "notes_insert_own" on public.notes for insert with check (auth.uid() = user_id);
create policy "notes_update_own" on public.notes for update using (auth.uid() = user_id);
create policy "notes_delete_own" on public.notes for delete using (auth.uid() = user_id);

create policy "quizzes_select_own" on public.quizzes for select using (auth.uid() = user_id);
create policy "quizzes_insert_own" on public.quizzes for insert with check (auth.uid() = user_id);
create policy "quizzes_update_own" on public.quizzes for update using (auth.uid() = user_id);
create policy "quizzes_delete_own" on public.quizzes for delete using (auth.uid() = user_id);
```

2. 取得 `supabaseUrl`（專案 URL）與 `supabaseAnonKey`（API 金鑰）。
3. 將 `final4/Config/Secrets.swift` 內的 placeholder 改成你的值（或複製 `Secrets.example.swift` 另存為 `Secrets.swift` 以排除版本控制）。

## 專案結構
```
final4/
├─ StudySnapApp.swift                  # App 入口
├─ ContentView.swift                   # TabView，提供 Home / 匯入 / 筆記 / 測驗 / 帳號
├─ Models/
│  └─ Note.swift                       # Note/Quiz/Question/SummaryResult/SupabaseUser 定義
├─ Services/
│  ├─ LocalSummarizer.swift            # LocalSummarizerProtocol + HeuristicSummarizer（可換 Foundation Models）
│  ├─ OCRService.swift                 # Vision OCR
│  ├─ PDFTextExtractor.swift           # PDFKit 文字抽取
│  ├─ QuizGenerator.swift              # 10 題四選一題庫生成
│  ├─ LocalStore.swift                 # JSONLocalStore（離線）
│  ├─ SupabaseService.swift            # REST Auth + CRUD
│  └─ SyncService.swift                # 以 updatedAt 合併/決策上傳下載
├─ ViewModels/
│  ├─ AppViewModel.swift               # 全域狀態、匯入/OCR/摘要/存取/同步
│  └─ QuizViewModel.swift              # 測驗答題邏輯
├─ Views/
│  ├─ Components/
│  │  ├─ DocumentScannerView.swift     # VisionKit 掃描
│  │  └─ PDFPicker.swift               # PDF 匯入
│  └─ Screens/
│     ├─ HomeView.swift                # 最近筆記 + 搜尋 + Demo seed
│     ├─ ImportView.swift              # PhotosPicker / 掃描 / PDF
│     ├─ NotesView.swift               # 筆記列表
│     ├─ NoteDetailView.swift          # 原文/摘要/重點/關鍵字 + Share + Quiz
│     ├─ QuizListView.swift            # 題庫列表
│     ├─ QuizView.swift                # 10 題測驗
│     └─ AccountView.swift             # 登入/註冊 + 同步
└─ Config/
   ├─ Secrets.swift                    # Supabase 設定（請填入）
   └─ Secrets.example.swift            # 範例
```

## 架構圖（文字）
- UI (SwiftUI Views): Home / Import / Notes / NoteDetail / Quiz / Account
- ViewModels: AppViewModel（資料流中心）、QuizViewModel（答題）
- Services: OCRService → Vision、PDFTextExtractor → PDFKit、LocalSummarizerProtocol（HeuristicSummarizer; 之後可換 Foundation Models）、QuizGenerator、LocalStore(JSON)、SupabaseService(REST Auth+CRUD)、SyncService(updatedAt 合併)
- Models: Note / Quiz / Question / SummaryResult / SupabaseUser
- Data flow: Import → OCR/PDF → Summarize → Quiz → LocalStore → (登入後) SyncService ↔ Supabase

## 功能與 Demo（1 分鐘講稿）
1. 開 App：Home 顯示最近筆記；若第一次啟動自動塞入 Demo Note + Quiz。
2. 匯入：到「匯入」選照片（PhotosPicker）、掃描紙本（VisionKit）、或 PDF。OCR 後自動摘要、抓關鍵字/重點並生成 10 題題庫。
3. 查看：在「筆記」或 Home 點進筆記，看原文/摘要/重點/關鍵字，可 Share 摘要或進入測驗。
4. 測驗：題庫為四選一，立即標示正誤並計算得分。
5. 帳號/同步：輸入 email/password 註冊或登入 Supabase，按「立即同步」；以 updatedAt 合併，較新的上傳，缺少的下載，離線仍可用本地功能。

## 測試清單（手動）
- 匯入：照片 OCR → 產生摘要/關鍵字/重點/題庫並顯示
- 掃描：VisionKit 掃描 1-2 頁 → 文字合併 → 產出筆記與題庫
- PDF：匯入文字型 PDF 正常抽字；掃描型 PDF 提示改用掃描
- 題庫：10 題四選一，提交後顯示分數與答題顏色
- 搜尋：在 Home 搜尋標題或關鍵字
- Share：在筆記頁 ShareLink 輸出摘要/關鍵字
- 離線：移除網路後仍可新增筆記並存到 JSON；恢復網路後登入同步
- Auth：註冊、登入、登出，登入後 sync 按鈕可運作
- 合併：同一筆記在本地更新摘要後同步，雲端應以更新時間較新的為準

## 降級方案說明
- Foundation Models 若不可用：已以 `LocalSummarizerProtocol` 抽象，預設 `HeuristicSummarizer`（TF/頻率 + 前幾句）可直接編譯；未來只需新增 Foundation Models 版本並注入即可。

## 權限（已在 Info 設定）
- NSCameraUsageDescription：掃描文件與拍攝照片
- NSPhotoLibraryUsageDescription / NSPhotoLibraryAddUsageDescription：讀取/存檔相簿

## 執行
1. 更新 `Config/Secrets.swift`。
2. 用 Xcode 26 打開專案，選擇 iOS 模擬器/實機，Build & Run。
