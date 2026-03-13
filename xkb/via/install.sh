#!/bin/bash

cp symbols/via /usr/share/X11/xkb/symbols/via
chmod 644 /usr/share/X11/xkb/symbols/via

EVDEV_XML="/usr/share/X11/xkb/rules/evdev.xml"
BACKUP_XML="${EVDEV_XML}.backup-$(date +%F_%H-%M-%S)"

# 1. Проверка прав root
if [ "$EUID" -ne 0 ]; then
  echo "Ошибка: Скрипт необходимо запускать с правами root (sudo)."
  exit 1
fi

# 2. Проверка, существует ли уже такая раскладка
if grep -q "<name>via</name>" "$EVDEV_XML"; then
  echo "Отмена: Раскладка 'via' уже прописана в $EVDEV_XML."
  exit 0
fi

echo "Создание резервной копии $EVDEV_XML -> $BACKUP_XML"
cp "$EVDEV_XML" "$BACKUP_XML"

# 3. Сохраняем XML-блок в переменную
read -r -d '' XML_BLOCK << 'EOF'
    <layout>
      
      <configItem>
        <name>via</name>
        <shortDescription>via</shortDescription>
        <description>VIA Layout (US)</description>
        <languageList>
          <iso639Id>eng</iso639Id>
        </languageList>
      </configItem>

      <variantList>
        <variant>
          <configItem>
            <name>ru</name>
            <description>VIA Layout (RU Phonetic)</description>
            <languageList>
              <iso639Id>rus</iso639Id>
            </languageList>
          </configItem>
        </variant>
      </variantList>

    </layout>
EOF

# 4. Вставка блока перед </layoutList>
echo "Инъекция XML-блока..."
awk -v block="$XML_BLOCK" '
  /<\/layoutList>/ && !inserted {
    print block
    inserted=1
  }
  { print }
' "$EVDEV_XML" > "${EVDEV_XML}.tmp" && mv "${EVDEV_XML}.tmp" "$EVDEV_XML"

# 5. Сброс прав на файл (на всякий случай)
chmod 644 "$EVDEV_XML"

echo "Готово! Не забудьте очистить кэш (sudo rm -rf /var/lib/xkb/*), чтобы изменения вступили в силу."