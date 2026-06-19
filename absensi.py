import serial
import firebase_admin
from firebase_admin import credentials, firestore
from firebase_admin.firestore import FieldFilter
from datetime import datetime, timedelta, timezone
import os
from pathlib import Path
import time
from google.api_core.exceptions import FailedPrecondition

# --- Inisialisasi Firebase ---
base_dir = Path(__file__).resolve().parent
env_cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
candidate_paths = [
    Path(env_cred_path) if env_cred_path else None,
    base_dir / "absensy-f456e-firebase-adminsdk-fbsvc-09da4c5062.json",
    base_dir / "serviceAccountKey.json",
]

service_account_path = next((str(p) for p in candidate_paths if p and p.exists()), None)
if not service_account_path:
    raise FileNotFoundError(
        "Service account JSON tidak ditemukan. Set GOOGLE_APPLICATION_CREDENTIALS "
        "atau taruh file JSON di folder project."
    )

cred = credentials.Certificate(service_account_path)
firebase_admin.initialize_app(cred)
db = firestore.client()

# --- Inisialisasi Serial Arduino ---
ser = serial.Serial('COM6', 9600)  # Ganti port sesuai Arduino
time.sleep(2)

print("Menunggu kartu RFID...")

try:
    while True:
        if ser.in_waiting > 0:
            line = ser.readline().decode('utf-8').strip()
            if line.startswith("UID kartu:"):
                uid = line.replace("UID kartu: ", "").replace(":", "").upper()
                print(f"UID Terdeteksi: {uid}")

                # Cari user berdasarkan card_id
                users_ref = db.collection('users')
                query = users_ref.where(filter=FieldFilter("card_id", "==", uid)).get()

                if query:
                    user_doc = query[0]
                    user_data = user_doc.to_dict()

                    user_id = int(user_data.get("id"))
                    card_id = user_data.get("card_id")

                    # Gunakan waktu UTC agar cocok dengan Firestore timestamp
                    now = datetime.now(timezone.utc)
                    start_of_day = datetime(now.year, now.month, now.day, tzinfo=timezone.utc)
                    end_of_day = start_of_day + timedelta(days=1)

                    absensi_ref = db.collection('absensi')
                    last_absen = None
                    try:
                        absensi_docs = absensi_ref \
                            .where(filter=FieldFilter("user_id", "==", user_id)) \
                            .where(filter=FieldFilter("in_time", ">=", start_of_day)) \
                            .where(filter=FieldFilter("in_time", "<", end_of_day)) \
                            .order_by("in_time", direction=firestore.Query.DESCENDING) \
                            .limit(1) \
                            .get()
                        if absensi_docs:
                            last_absen = absensi_docs[0]
                    except FailedPrecondition as e:
                        absensi_docs = absensi_ref \
                            .where(filter=FieldFilter("in_time", ">=", start_of_day)) \
                            .where(filter=FieldFilter("in_time", "<", end_of_day)) \
                            .order_by("in_time", direction=firestore.Query.DESCENDING) \
                            .limit(200) \
                            .get()
                        for doc in absensi_docs:
                            if doc.to_dict().get("user_id") == user_id:
                                last_absen = doc
                                break
                        if last_absen is None:
                            print(f"[!] Firestore butuh composite index untuk query cepat. Detail: {e}")

                    if last_absen is not None:
                        absen_data = last_absen.to_dict()

                        if absen_data.get("out_time") is None:
                            in_time = absen_data["in_time"]
                            # Pastikan in_time dalam UTC
                            if isinstance(in_time, datetime):
                                selisih = now - in_time
                                if selisih.total_seconds() >= 3600:
                                    absensi_ref.document(last_absen.id).update({
                                        "out_time": firestore.SERVER_TIMESTAMP
                                    })
                                    print(f"[✔] Out time dicatat untuk user_id: {user_id} ({user_data.get('fullname')})")
                                else:
                                    print("[⏱] Belum 1 jam sejak in_time. Tidak mencatat out_time.")
                            else:
                                print("[⚠] Format in_time tidak valid.")
                        else:
                            print("[!] Absen sudah lengkap hari ini.")
                    else:
                        # Belum absen hari ini, catat in_time
                        absensi_data = {
                            "id": str(user_id),
                            "card_id": card_id,
                            "user_id": user_id,
                            "keterangan": "hadir",
                            "in_time": firestore.SERVER_TIMESTAMP,
                            "out_time": None
                        }
                        db.collection("absensi").add(absensi_data)
                        print(f"[✔] In time dicatat untuk user_id: {user_id} ({user_data.get('fullname')})")
                    print("-" * 40)
                else:
                    print("[✖] UID tidak ditemukan dalam koleksi users.\n")

except KeyboardInterrupt:
    print("Program dihentikan oleh pengguna.")
    ser.close()
