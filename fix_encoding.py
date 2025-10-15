import os
import glob

def fix_file_encoding(file_path):
    try:
        # Читаем файл как байты
        with open(file_path, 'rb') as f:
            raw_data = f.read()

        # Пробуем декодировать как UTF-8
        try:
            text = raw_data.decode('utf-8')
            # Если успешно, проверим, нет ли "битых" байтов вроде 0xc2
            # Это может быть валидный UTF-8, но если он "неполный" — будет ошибка
            # Но мы всё равно попробуем пересохранить
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(text)
            print(f"UTF-8 OK: {file_path}")
            return True
        except UnicodeDecodeError:
            # Если UTF-8 не сработал, пробуем другие кодировки
            for encoding in ['cp1251', 'latin-1', 'utf-8-sig']:
                try:
                    text = raw_data.decode(encoding)
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(text)
                    print(f"Fixed ({encoding}): {file_path}")
                    return True
                except UnicodeDecodeError:
                    continue
            print(f"Failed to decode: {file_path}")
            return False
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def scan_and_fix():
    # Ищем все .py файлы в проекте
    py_files = glob.glob("**/*.py", recursive=True)
    problematic_files = []
    fixed_files = []

    for file_path in py_files:
        try:
            # Проверим, можно ли прочитать как UTF-8
            with open(file_path, 'r', encoding='utf-8') as f:
                f.read()
            print(f"UTF-8 OK: {file_path}")
        except UnicodeDecodeError:
            print(f"UTF-8 ERROR: {file_path}")
            problematic_files.append(file_path)
            if fix_file_encoding(file_path):
                fixed_files.append(file_path)

    print("\n--- Summary ---")
    print(f"Found {len(problematic_files)} problematic files:")
    for f in problematic_files:
        print(f"  - {f}")
    print(f"Successfully fixed {len(fixed_files)} files.")
    for f in fixed_files:
        print(f"  - {f}")

if __name__ == "__main__":
    scan_and_fix()