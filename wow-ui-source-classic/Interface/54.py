import os

# --- НАСТРОЙКИ ---

# 1. Укажите точное имя папки аддона, который нужно обработать.
#    В вашем случае это 'Blizzard_AuctionHouseUI'.
source_directory = 'Blizzard_AuctionHouseUI'

# 2. Укажите имя файла, в который будет сохранен результат.
output_filename = 'Blizzard_AuctionHouseUI_Combined.txt'

# 3. Список расширений файлов, которые нужно включить (lua, xml, toc - стандарт для аддонов).
#    Если хотите включить абсолютно все файлы, оставьте список пустым: []
included_extensions = ['.lua', '.xml', '.toc']

# 4. Список элементов для игнорирования (обычно не требуется для одной папки).
ignored_items = ['.git', '.github']

# --- ОСНОВНОЙ КОД ---

def combine_files_in_directory(root_dir, output_file):
    """
    Обходит все файлы в ОДНОЙ указанной директории (и ее подпапках)
    и записывает их пути и содержимое в выходной файл.
    """
    # Проверяем, существует ли указанная папка
    if not os.path.isdir(root_dir):
        print(f'ОШИБКА: Папка не найдена: "{root_dir}"')
        print('Убедитесь, что скрипт находится в той же папке, что и директория аддона (например, в папке "AddOns").')
        return

    try:
        # Открываем выходной файл для записи
        with open(output_file, 'w', encoding='utf-8') as outfile:
            print(f'Начинаю обработку папки: "{root_dir}"')
            
            # os.walk рекурсивно обходит все папки и файлы
            for dirpath, dirnames, filenames in os.walk(root_dir):
                
                # Исключаем из обхода ненужные папки (если они есть внутри)
                dirnames[:] = [d for d in dirnames if d not in ignored_items]

                for filename in sorted(filenames): # Сортируем для предсказуемого порядка
                    # Проверяем, нужно ли игнорировать файл
                    if filename in ignored_items:
                        continue

                    # Если список расширений задан, проверяем, подходит ли файл
                    if included_extensions and not any(filename.endswith(ext) for ext in included_extensions):
                        continue
                    
                    # Формируем полный путь к файлу
                    file_path = os.path.join(dirpath, filename)
                    # Создаем относительный путь для красивого заголовка
                    relative_path = os.path.relpath(file_path, os.path.dirname(root_dir))

                    try:
                        # Открываем исходный файл для чтения
                        with open(file_path, 'r', encoding='utf-8', errors='ignore') as infile:
                            content = infile.read()
                            
                            outfile.write(f'--- START OF FILE: {relative_path} ---\n\n')
                            outfile.write(content)
                            outfile.write(f'\n\n--- END OF FILE: {relative_path} ---\n\n')
                            print(f'  -> Добавлен файл: {relative_path}')

                    except Exception as e:
                        error_message = f'*** ОШИБКА: Не удалось прочитать файл {relative_path}: {e} ***\n\n'
                        print(error_message)
                        outfile.write(error_message)

        print(f'\nГотово! Все файлы из "{root_dir}" были объединены в файл "{output_file}"')

    except Exception as e:
        print(f'Произошла непредвиденная ошибка: {e}')


# Запускаем функцию
if __name__ == '__main__':
    combine_files_in_directory(source_directory, output_filename)