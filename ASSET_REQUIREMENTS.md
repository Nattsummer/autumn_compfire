# Autumn - Pixel Art Asset Requirements & Progress Checklist

เอกสารรายการและสเปก Asset งานศิลป์ (Pixel Art) สำหรับโปรเจกต์เกม **Autumn**  
มุมมอง: **2D Side-scroller (Cinematic Narrative / จนถึงช่วง End Game)**  
สไตล์ภาพ: **Pixel Art โทนสีอบอุ่น บรรยากาศป่าฤดูใบไม้ร่วง (Mood & Tone คล้าย Until Then)**  

*(หมายเหตุ: ขนาด Resolution และจำนวนเฟรมแอนิเมชัน ไม่มีการฟิกซ์ตายตัว สามารถออกแบบและกำหนดได้อิสระตามความเหมาะสมของสไตล์งาน)*

---

## 📋 Master Asset Checklist (ภาพรวมความคืบหน้า)

สามารถติ๊กถูก `[x]` ในเช็กลิสต์นี้เพื่อติดตามสถานะการทำงานได้ทันที:

### 1. ตัวละคร (Player Character)
- [x] `player_idle_hands` (ยืนมือเปล่า)
- [x] `player_walk_hands` (เดินมือเปล่า)
- [x] `player_gather_hands` (ก้มเก็บใบไม้)
- [x] `player_idle_broom` (ยืนถือไม้กวาด)
- [x] `player_walk_broom` (เดินถือไม้กวาด)
- [x] `player_sweep_broom_hit` (กวาดไม้กวาด)
- [x] `player_idle_blower` (ยืนสะพายเครื่องเป่าลม)
- [x] `player_walk_blower` (เดินสะพายเครื่องเป่าลม)
- [x] `player_blow_air_loop` (เป่าลมเครื่องเป่าลม)

### 2. กองใบไม้บนพื้นดิน (Leaf Piles - 5 Tiers)
- [x] **Tier 0: Scatter** (เศษใบไม้ประปราย 1-5 ใบ)
- [x] **Tier 1: Small** (กองพูนเตี้ยเรี่ยดิน 6-20 ใบ)
- [x] **Tier 2: Medium** (กองขนาดกลาง 21-60 ใบ)
- [x] **Tier 3: Large** (กองหนาแน่นระดับแข้ง 61-150 ใบ)
- [x] **Tier 4: Massive** (กองมหึมาระดับเอว 151-300+ ใบ)
- [ ] *(Optional)* เศษใบไม้อนุภาคเดี่ยว (`leaf_particle_yellow`, `orange`, `red`)

### 3. แคมป์ไฟ (Campfire Stages & Climax)
- [x] `campfire_logs.png` (ฐานขอนไม้ไขว้ + หินล้อม)
- [ ] **Stage 0: Embers** (ไฟขนาดย่อมติดขอนไม้ ตัวคูณ x1.0)
- [ ] **Stage 1: Warming** (ไฟลุกสม่ำเสมอ เริ่มเห็นแกนสีเหลือง)
- [ ] **Stage 2: Blazing** (ไฟโหมแรง สะเก็ดไฟพวยพุ่ง)
- [ ] **Stage 3: Infernal** (ไฟบ้าคลั่ง ควันหนา ใกล้วิกฤต)
- [ ] **Stage 4: Wildfire** (มหาเพลิงผลาญป่า Climax End Game)

### 4. สภาพแวดล้อม & Foreground (Environment)
- [x] **Autumn Tree (Swaying)** (ต้นไม้พริ้วไหวตามลม)
- [x] **Autumn Tree (Burning)** (ต้นไม้ไฟลุกไหม้สำหรับ End Game)
- [x] **Tent (Camp Wind Flutter)** (เต็นท์ผ้าใบพริ้วลม)
- [ ] **Foreground Tree Trunk** (ลำต้นไม้ใหญ่หน้ากล้อง เคลื่อนผ่านเร็ว)
- [ ] **Foreground Overhanging Branch** (กิ่งไม้ห้อยบนหน้ากล้อง พริ้วไหว)
- [x] **Foreground Bushes & Grass** (พุ่มไม้/ยอดหญ้าหน้ากล้อง)
- [x] **Ambient Falling Leaves VFX** (ใบไม้ร่วงหล่นปลิวตามสายลม)
- [ ] **Platform Ground Tileset** (แผ่นพื้นผิวดินป่า)
- [x] **Sky (Normal Twilight)** (ท้องฟ้ายามสนธยาปกติ)
- [ ] **Sky (Wildfire Apocalypse)** (ท้องฟ้าสีเพลิงไหม้ป่า)
- [x] **Background Mountains / Far Trees** (ทิวเขา/แนวป่าชั้นหลัง Parallax)

### 5. เอฟเฟกต์เครื่องมือ (VFX)
- [x] `vfx_sweep_hit.png` (เอฟเฟกต์กวาดโดนใบไม้)
- [x] `vfx_sweep_wind.png` (เส้นสายลมกวาดลมเปล่า)
- [x] `vfx_blow_leaves.png` (ลมพัดเศษใบไม้กระจาย)
- [x] `vfx_blow_wind.png` (ละอองลมเป่าลมเปล่า)

### 6. UI & ปุ่มกด (HUD / Icons)
- [x] `icon_hands.png` (ไอคอนมือเปล่า)
- [x] `icon_broom.png` (ไอคอนไม้กวาด)
- [x] `icon_blower.png` (ไอคอนเครื่องเป่าลม)
- [x] `icon_coin.png` (ไอคอนเหรียญทอง)
- [x] `icon_leaf.png` (ไอคอนใบไม้)
- [x] ปุ่มกดคีย์บอร์ด (`key_e.png`, `key_a.png`, `key_d.png`, `key_space.png`)

---

## 1. ข้อมูลทางเทคนิคทั่วไป (General Technical Specs)

- **Texture Filter ใน Engine**: `Nearest` (เพื่อรักษาความคมชัดของเม็ดพิกเซล ห้ามเบลอขอบ)
- **Format ไฟล์**: `.png` (โปร่งใส Transparent RGBA)
- **Layout สไปรต์แอนิเมชัน**: สามารถส่งเป็น **Horizontal Sprite Sheet** (แถวแนวนอน) หรือแยกไฟล์เฟรมเดี่ยวรันลำดับตัวเลขได้ตามสะดวก
- **จุดศูนย์ถ่วง (Pivot Point)**: 
  - ตัวละครและวัตถุบนพื้นดินทั้งหมดจะยึด **กึ่งกลางฐานล่าง (Bottom-Center)** ที่ระดับเท้า/โคนต้นไม้ เพื่อให้จัดวางลงบนพื้นดินและสเกลขนาดได้ตรงตำแหน่งเสมอ

---

## 2. หมวดตัวละคร (Player Character)

ตัวละครหลักวาดหันหน้าไปทางขวาเป็นค่าเริ่มต้น (ในเอ็นจิ้นจะทำการ Flip แนวนอนอัตโนมัติตามทิศทางเดิน)

| Animation Name | ประเภท | คำอธิบาย & ท่าทาง |
| :--- | :---: | :--- |
| `player_idle_hands` | Loop | ยืนมือเปล่า ตัวโยกตามจังหวะหายใจเบา ๆ |
| `player_walk_hands` | Loop | เดินมือเปล่า ท่วงท่าสบาย ๆ ผ่อนคลาย |
| `player_gather_hands` | One-shot | ก้มตัวลงหยิบใบไม้ขึ้นมาจากพื้น |
| `player_idle_broom` | Loop | ยืนพักถือไม้กวาด |
| `player_walk_broom` | Loop | เดินถือ/ลากไม้กวาด |
| `player_sweep_broom_empty` | One-shot | **กวาดลมเปล่า (ไม่โดนใบไม้)**: ตวัดกวาดไม้กวาด มีเฉพาะเส้นสายลมพริ้วบาง ๆ |
| `player_sweep_broom_hit` | One-shot | **กวาดโดนใบไม้**: ตวัดกวาดเต็มแรง พร้อมเศษใบไม้แตกฮือและพุ่งไปข้างหน้า |
| `player_idle_blower` | Loop | ยืนถือ/สะพายเครื่องเป่าลม |
| `player_walk_blower` | Loop | เดินสะพายเครื่องเป่าลม |
| `player_blow_air_loop` | Loop | **เป่าลมเปล่า (ไม่โดนใบไม้)**: กดค้าง มีเฉพาะเส้นสายลมโปร่งใสพุ่งออกจากปากท่อ |
| `player_blow_leaves_loop` | Loop | **เป่าโดนใบไม้**: ปลายท่อมีเศษใบไม้ปลิวคลุ้ง พุ่งกระจายไปข้างหน้าตามแรงลม |

> **คำแนะนำเทคนิคศิลป์ (Art Tip):**
> สามารถเลือกทำได้ 2 รูปแบบตามความสะดวกของคนวาด:
> 1. **แบบรวมในตัวละคร (Baked-in)**: วาดเศษใบไม้ติดไปกับสไปรต์ตัวละครเลย
> 2. **แบบแยกชิ้น VFX (Modular)**: ตัวละครใช้ท่ากวาด/เป่าปกติ แล้วแยกชิ้นเอฟเฟกต์ลม/ใบไม้กระจาย (`vfx_sweep_hit.png`, `vfx_blow_leaves.png`) ออกมาต่างหาก เพื่อให้เอ็นจิ้นดึงไปแสดงผลทับตำแหน่งปากท่อ/ปลายไม้กวาดได้อิสระ

---

## 3. หมวดกองใบไม้บนพื้นดิน (Leaf Piles - 5 Tiers)

กองใบไม้ที่ค่อย ๆ พูนสูงขึ้นตามจำนวนใบไม้ที่ถูกกวาดมากองรวมกันในช่องพื้นดิน มี 5 ระดับความหนาแน่น:

| ระดับ (Tier) | ช่วงจำนวนใบไม้ในเกม | ลักษณะรูปทรง & คำอธิบายกราฟิก |
| :--- | :---: | :--- |
| **Tier 0: Scatter** | 1 - 5 ใบ | เศษใบไม้ประปรายไม่กี่ใบ แปะราบบนผิวดิน โทนเหลืองทอง |
| **Tier 1: Small** | 6 - 20 ใบ | กองพูนเตี้ย ๆ เรี่ยดิน เริ่มเห็นรูปทรงกองใบไม้ โทนส้ม |
| **Tier 2: Medium** | 21 - 60 ใบ | กองขนาดกลาง นูนเด่นขึ้นมาชัดเจน โทนส้มแอมเบอร์ |
| **Tier 3: Large** | 61 - 150 ใบ | กองหนาแน่นสูงระดับแข้งตัวละคร โทนแดงส้ม Autumn Amber |
| **Tier 4: Massive** | 151 - 300+ ใบ | กองมหึมาพูนสูงระดับเอวตัวละคร โทนแดงเข้มเบอร์กันดี |

> **VFX อนุภาคเพิ่มเติม (Optional):**
> - `leaf_particle_yellow.png`: เศษใบไม้เดี่ยวสีเหลือง
> - `leaf_particle_orange.png`: เศษใบไม้เดี่ยวสีส้ม
> - `leaf_particle_red.png`: เศษใบไม้เดี่ยวสีแดงเข้ม

---

## 4. หมวดกองไฟ (Campfire Stages & Climax)

ชิ้นส่วนฐานขอนไม้ (Static) แยกกับเปลวไฟ (Animated Loop):
- `campfire_logs.png`: ขอนไม้ไขว้ + ก้อนหินล้อมรอบฐาน

| ระดับ (Stage) | ช่วง Heat / สถานะ | ประเภท | คำอธิบายกราฟิก |
| :--- | :---: | :---: | :--- |
| **Stage 0: Embers** | Heat = 10 (ปกติ) | Loop | ไฟขนาดย่อมติดขอนไม้ เปลวไฟพริ้วเบา ๆ สะเก็ดไฟน้อยมาก (ตัวคูณ x1.0) |
| **Stage 1: Warming** | Heat 25 - 60 | Loop | เปลวไฟลุกสม่ำเสมอ เริ่มเห็นเปลวเพลิงสีส้มและแกนในสีเหลืองชัดเจน |
| **Stage 2: Blazing** | Heat 60 - 120 | Loop | กองไฟโหมแรง พุ่งสูงพริ้วไหวเร็ว มีสะเก็ดไฟลอยขึ้นอย่างต่อเนื่อง |
| **Stage 3: Infernal** | Heat 120 - 199 | Loop | เปลวไฟบ้าคลั่ง โหมรุนแรงมาก ควันเริ่มหนาตัว ใกล้ถึงจุดวิกฤต |
| **Stage 4: Wildfire** | Heat 200+ (Endgame) | Loop | **มหาเพลิงผลาญป่า (Climax)** เปลวไฟขนาดยักษ์พุ่งสูงท่วมฟ้า ซัดลามไปทั่วฉาก |

---

## 5. หมวดสภาพแวดล้อม (Environment & Background)

หมวดนี้เน้นบรรยากาศแบบ Cinematic Depth (*Until Then* style) โดยแบ่งระนาบความลึก และเพิ่มชีวิตชีวาด้วยแอนิเมชันพริ้วไหวตามแรงลมฤดูใบไม้ร่วง

### ตารางรายการ Asset สภาพแวดล้อม:
| ชื่อ Asset | ประเภท | รายละเอียด |
| :--- | :---: | :--- |
| **Autumn Tree (Swaying)** | Loop Animation | **ต้นไม้พริ้วไหว**: พุ่มใบและกิ่งก้านโยกพริ้วตามแรงลมอ่อน ๆ อย่างนุ่มนวล พร้อมมีใบไม้เล็ก ๆ หลุดปลิวเป็นจังหวะ |
| **Autumn Tree (Burning)** | Loop Animation | ต้นไม้ในสภาพถูกเปลวไฟลุกโชนท่วมพุ่มใบ สำหรับฉาก End Game (ไฟไหม้ลามป่า) |
| **Tent (Camp Wind Flutter)** | Loop Animation | **เต็นท์พริ้วลม**: ชายผ้าใบเต็นท์และเชือกยึดสะบัดพริ้วตามสายลมออทัมน์ ไม่แข็งทื่อ |
| **Foreground Tree Trunk (หน้ากล้อง)** | Static Sprite | **ลำต้นไม้ใหญ่หน้ากล้อง**: ลำต้นไม้ขนาดใหญ่โทนสีเข้ม (Silhouette/Dark tone) วางชิดขอบจอ เคลื่อนผ่านเร็วกว่าตัวละครเวลาเดิน (Parallax 1.35x - 1.5x) |
| **Foreground Overhanging Branch (พริ้วไหว)** | Loop Animation | **กิ่งไม้ห้อยบนหน้ากล้อง**: กิ่งไม้พร้อมพุ่มใบไม้ส้มห้อยย้อยลงมาจากขอบจอบน มีแอนิเมชันพริ้วไหวตามลมเบา ๆ บังหน้าจอเล็กน้อย |
| **Foreground Bushes & Tall Grass** | Loop Animation | กอหญ้าและพุ่มไม้รกขอบจอด้านล่างหน้ากล้อง พริ้วไหวและเคลื่อนผ่านเร็ว |
| **Ambient Falling Leaves VFX** | Loop Animation | **ใบไม้ร่วงหล่น**: แอนิเมชันใบไม้หมุนคว้างและร่อนส่ายไปมาตามสายลมจากยอดไม้ลงสู่พื้นอย่างต่อเนื่อง |
| **Platform Ground Tileset** | Tileset / Autotile | ผิวหน้าดินป่าที่มีหญ้าสีเขียวหม่น/เศษใบไม้คลุมดิน และชั้นผิวดินด้านล่าง |
| **Sky (Normal Twilight)** | Seamless แนวนอน | ท้องฟ้ายามสนธยา/ค่ำคืนในป่า โทนสีน้ำเงินครามเข้มไล่สีม่วง (Twilight) |
| **Sky (Wildfire Apocalypse)**| Seamless แนวนอน | ท้องฟ้าสีเพลิงลุกโชน โทนส้มแดงเข้ม (สำหรับฉากจบไฟไหม้ป่า) |
| **Background Mountain / Far Trees**| Parallax Layer | แนวทิวเขาและแนวป่าชั้นหลังแบบ Silhouette ช่วยเพิ่มมิติความลึก (Parallax 0.2x - 0.4x) |

---

### ลำดับชั้น Parallax & มิติความลึก (Depth Layering):

```text
[กล้อง Camera2D]
       │
       ▼
┌─────────────────────────────────────────────────────────────┐
│ 1. Foreground Layer (Z: +10) | Parallax Scroll: 1.35x - 1.5x│  <-- กิ่งไม้/ลำต้นหน้ากล้อง เคลื่อนผ่านเร็วมาก + พริ้วไหว
├─────────────────────────────────────────────────────────────┤
│ 2. Gameplay Layer   (Z:   0) | Parallax Scroll: 1.0x        │  <-- ตัวละคร, กองไฟ, เต็นท์พริ้ว, ต้นไม้พริ้ว, กองใบไม้
├─────────────────────────────────────────────────────────────┤
│ 3. Midground Forest (Z:  -5) | Parallax Scroll: 0.8x        │  <-- แนวต้นไม้ชั้นหลัง
├─────────────────────────────────────────────────────────────┤
│ 4. Far Mountains    (Z: -15) | Parallax Scroll: 0.3x        │  <-- ทิวเขาชั้นไกล
├─────────────────────────────────────────────────────────────┤
│ 5. Sky Background   (Z: -20) | Parallax Scroll: 0.0x        │  <-- ท้องฟ้าคงที่
└─────────────────────────────────────────────────────────────┘
```

> **เทคนิคสำคัญสำหรับ Foreground:**
> - วาดให้มีโทนสีเข้มกว่า Gameplay Layer เล็กน้อย (หรือกึ่ง Silhouette) เพื่อไม่ให้แย่งจุดโฟกัสสายตาจากตัวละคร
> - สามารถใส่ Gaussian Blur หรือขอบนุ่มเบา ๆ ในเอ็นจิ้นเพื่อจำลองเลนส์หน้าชัดหลังเบลอ (Cinematic Depth of Field)

---

## 6. หมวด UI & ไอคอน (HUD / Icons)

| ชื่อ Asset | รายละเอียด |
| :--- | :--- |
| `icon_hands.png` | ไอคอนมือเปล่า |
| `icon_broom.png` | ไอคอนไม้กวาด |
| `icon_blower.png` | ไอคอนเครื่องเป่าลม |
| `icon_coin.png` | ไอคอนเหรียญทอง (สไปรต์เดี่ยวหรือ Loop หมุน) |
| `icon_leaf.png` | ไอคอนใบไม้สำหรับแสดงจำนวนในมือ (x/2) |
| `key_e.png`, `key_a.png`, `key_d.png`, `key_space.png` | ปุ่มกดคีย์บอร์ดสไตล์ Pixel Art สำหรับแสดงปุ่มปฏิสัมพันธ์ |

---

## 7. โครงสร้างโฟลเดอร์ในโปรเจกต์ (Project Directory Layout)

เมื่อวาด Asset เสร็จแล้ว ให้เซฟไฟล์และจัดวางลงในโฟลเดอร์ตามโครงสร้างนี้ได้ทันที:

```text
res://
├── assets/
│   ├── characters/
│   │   └── player/
│   │       ├── player_hands_sheet.png
│   │       ├── player_broom_sheet.png
│   │       └── player_blower_sheet.png
│   ├── environment/
│   │   ├── campfire/
│   │   │   ├── campfire_logs.png
│   │   │   ├── fire_stage_0.png
│   │   │   ├── fire_stage_1.png
│   │   │   ├── fire_stage_2.png
│   │   │   ├── fire_stage_3.png
│   │   │   └── fire_stage_4_wildfire.png
│   │   ├── leaf_piles/
│   │   │   ├── pile_tier_0.png
│   │   │   ├── pile_tier_1.png
│   │   │   ├── pile_tier_2.png
│   │   │   ├── pile_tier_3.png
│   │   │   └── pile_tier_4.png
│   │   ├── trees/
│   │   │   ├── tree_autumn_swaying_sheet.png
│   │   │   └── tree_autumn_burning_sheet.png
│   │   ├── camp/
│   │   │   └── tent_flutter_sheet.png
│   │   ├── foreground/
│   │   │   ├── fg_tree_trunk_large.png
│   │   │   ├── fg_branch_overhead_sheet.png
│   │   │   └── fg_bush_grass_sheet.png
│   │   └── background/
│   │       ├── sky_twilight.png
│   │       ├── sky_wildfire.png
│   │       ├── bg_mountain_far.png
│   │       └── bg_forest_mid.png
│   ├── vfx/
│   │   ├── vfx_sweep_hit.png                 # เอฟเฟกต์ใบไม้แตกกระจาย (กวาดโดน)
│   │   ├── vfx_sweep_wind.png                # เส้นลมบาง ๆ (กวาดลมเปล่า)
│   │   ├── vfx_blow_leaves.png               # ลมพัดเศษใบไม้ปลิวคลุ้ง (เป่าโดน)
│   │   ├── vfx_blow_wind.png                 # ละอองลมโปร่งใส (เป่าลมเปล่า)
│   │   └── vfx_ambient_falling_leaves.png    # ใบไม้ร่วงหล่นปลิวตามสายลม
│   └── ui/
│       ├── icons/
│       │   ├── icon_hands.png
│       │   ├── icon_broom.png
│       │   ├── icon_blower.png
│       │   ├── icon_coin.png
│       │   └── icon_leaf.png
│       └── keys/
│           ├── key_e.png
│           ├── key_a.png
│           ├── key_d.png
│           └── key_space.png
```
