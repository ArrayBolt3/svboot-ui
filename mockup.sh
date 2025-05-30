#!/bin/bash

set -u

drive_list=( 'Samsung SSD 990 PRO #1' 'USB SanDisk 3.2Gen1 #2' 'USB TeamGroup 2.0 #3' )
drive_id_list=( 'samsung_n1' 'sandisk_n2' 'teamgroup_n3' )
key_info=(
  # fingerprint|organization|ca|expired
  '0123 4567 8901 2345  6789 0123 4567 8901|Microsoft|Microsoft 3rd Party CA|n'
  '0987 6543 2109 8765  4321 0987 6543 2109|Canonical|Canonical Signing Key|n'
  '5647 3829 1056 4738  2910 5647 3829 1056|Arch Linux|Arch Linux Signing Key|n'
  '9876 5432 1098 7654  3210 9876 5432 1098|Debian|Debian Signing Key|n'
  '8765 4321 0987 6543  2109 8765 4321 0987|Fedora|Fedora Signing Key|y'
  '7654 3210 9876 5432  1098 7654 3210 9876|Microsoft|Windows 2023 UEFI CA|n'
)
boot_data_db=(
  # Bash arrays are awful. That's what I have to say about that.

  # drive id:
  # path|key count[|fingerprint|passes verification...]|hash;
  "samsung_n1:\
\\EFI\\BOOT\\BOOTX64.EFI|1|0123 4567 8901 2345  6789 0123 4567 8901|y|1e94a2ef9584181b0b4624fe0ca3c852557a9b61f02cfced7ce9825da2cbf9b2;\
\\EFI\\BOOT\\fbx64.efi|1|0987 6543 2109 8765  4321 0987 6543 2109|y|6da51bc60d51ff01eefbc7b6090044692a585951a9efa65744a26585f9454d23;\
\\EFI\\BOOT\\mmx64.efi|1|0987 6543 2109 8765  4321 0987 6543 2109|y|f24863809940818de0e7b498ec7e639b00904d403976691c8bea7159f3f7036f;\
\\EFI\\ubuntu\\grubx64.efi|1|0987 6543 2109 8765  4321 0987 6543 2109|y|90a877dee6242a5d46424f0fa9677a2a15f2de913ad545aa09a6fdba846a5fd7;\
\\EFI\\ubuntu\\mmx64.efi|1|0987 6543 2109 8765  4321 0987 6543 2109|y|527ae442f6ce06f46143b5d8c389b8fec1944a60bd1a597da16747e2ee92b8e5;\
\\EFI\\ubuntu\\shimx64.efi|1|0123 4567 8901 2345  6789 0123 4567 8901|y|f8568665a370916edab60be9db0efd7d37ac644ed9c60a8e28691ded37b243ba;\
\\EFI\\arch\\grubx64.efi|0|y|a831af01e4fb5e3c9457120e1d08ea13d98a0a47b62728c284b7f502d535965c;\
\\EFI\\arch\\shimx64.efi|2|5647 3829 1056 4738  2910 5647 3829 1056|y|0123 4567 8901 2345  6789 0123 4567 8901|y|f0068d3b418ae039c309574b33901b82404025eb46c2e983246b9c3976ba7e83"

  "sandisk_n2:\
\\EFI\\BOOT\\BOOTX64.EFI|1|0123 4567 8901 2345  6789 0123 4567 8901|n|7e79c60c3d1e182664a1bce9a70a13462e5da4a087ae5aa75950695ce7431b0a;\
\\EFI\\BOOT\\grubx64.efi|0|y|6fe6e1bcbe6cf6baec8e056d40361ca1aa715cc04ddcc2855351de060b84350b"

  "teamgroup_n3:\
\\EFI\\debian\\shimx64.efi|1|0123 4567 8901 2345  6789 0123 4567 8901|y|4dd07143c1cdc8959482db6404909fdc05685e71d823df880bc1b006d2a2e689;\
\\EFI\\debian\\grubx64.efi|1|9876 5432 1098 7654  3210 9876 5432 1098|y|4d554f16d78622adb28ef6c4ba17225d555998d3ad2fd7130e3618b19ce1b677;\
\\EFI\\fedora\\shimx64.efi|2|0123 4567 8901 2345  6789 0123 4567 8901|y|8765 4321 0987 6543  2109 8765 4321 0987|y|51c9d83d5629f1b224a0a9fdbc8a00b9a69c2afaf15f6d25970c1b836b6501c4;\
\\EFI\\fedora\\systemd-bootx64.efi|1|8765 4321 0987 6543  2109 8765 4321 0987|y|95c8f4612965ee4b0ed07988624796aaa64930313a531e952619cd23fe2e3a0a;\
\\EFI\\Microsoft\\bootmgfw.efi|1|7654 3210 9876 5432  1098 7654 3210 9876|y|39eae1079671e9357fd1d5e8695a25a14d6a5ad58a3da6b87ecdacfbd6a9298b"
)
boot_order=(
  # id|target device|target path
  'Boot0000|samsung_n1|\EFI\ubuntu\shimx64.efi'
  'Boot0001|samsung_n1|\EFI\ubuntu\grubx64.efi'
  'Boot0002|samsung_n1|\EFI\arch\grubx64.efi'
  'Boot0003|teamgroup_n3|\EFI\fedora\shimx64.efi'
  'Boot0004|teamgroup_n3|\EFI\fedora\systemd-bootx64.efi'
)

dialog_title='Sovereign Boot Configuration'
bootloader_trust_nokey_text="$(cat <<EOF
The following bootloader is present on the system but is not marked as
trusted:

  Boot device: XXX_BOOT_DEVICE_XXX
  Bootloader path: XXX_BOOTLOADER_PATH_XXX

The bootloader has NOT been signed by its author, so the system cannot help
you verify who created this bootloader or if it is trustworthy.

Would you like to trust this bootloader and boot the system with it?
EOF
)"
bootloader_trust_invalidkey_text="$(cat <<EOF
The following bootloader is present on the system but is not marked as
trusted:

  Boot device: XXX_BOOT_DEVICE_XXX
  Bootloader path: XXX_BOOTLOADER_PATH_XXX

The bootloader has been signed by its author, but the signature is invalid.
It is highly recommended that you do NOT use this bootloader, as it may have
been maliciously modified.

Would you like to trust this bootloader and boot the system with it?
EOF
)"
bootloader_trust_expiredkey_text="$(cat <<EOF
The following bootloader is present on the system but is not marked as
trusted:

  Boot device: XXX_BOOT_DEVICE_XXX
  Bootloader path: XXX_BOOTLOADER_PATH_XXX
  Key fingerprint:
    XXX_KEY_FINGERPRINT_XXX
  Key info (unreliable):
    Organization Name: XXX_KEY_ORG_XXX
    Key Name: XXX_KEY_NAME_XXX

The bootloader has been signed by its author. However, the key used to sign
the bootloader is expired. It is possible, though unlikely, that a third party
has stolen the key from the author and used it to sign a malicious bootloader.

Would you like to trust this bootloader and boot the system it?
EOF
)"
bootloader_trust_goodkey_text="$(cat <<EOF
The following bootloader is present on the system but is not marked as
trusted:

  Boot device: XXX_BOOT_DEVICE_XXX
  Bootloader path: XXX_BOOTLOADER_PATH_XXX
  Key fingerprint:
    XXX_KEY_FINGERPRINT_XXX
  Key info (unreliable):
    Organization Name: XXX_KEY_ORG_XXX
    Key Name: XXX_KEY_NAME_XXX

The bootloader has been signed by its author and passes verification. If you
trust the key's owner to only sign safe bootloaders, this bootloader can be
safely used. You may use the key fingerprint to verify the key's authenticity.

Would you like to trust this bootloader and boot the system it?
EOF
)"

bootloader_trust_dialog() {
  declare drive_id bootloader_path bootloader_key_count bootloader_key_list \
    bootloader_hash boot_data_line bit_list trust_option_list_nokey \
    trust_option_list_key drive_name \
    boot_data_drive_id boot_data_sb_info sb_info_line \
    sb_info_bootloader_path idx prompt_msg key_info_idx bootloader_key_org \
    bootloader_key_ca bootloader_key_expired result_text \
    bootloader_key_valid_list

  drive_id="${1:-}"
  drive_name=''
  bootloader_path="${2:-}"
  bootloader_key_count=0
  bootloader_key_list=()
  bootloader_key_valid_list=()
  bootloader_hash=''
  boot_data_sb_info=()
  result_text=''

  trust_option_list_nokey=(
    'trust-hash' "Mark this specific bootloader as trusted"
    'skip' "Skip this bootloader"
    'distrust-hash' "Mark this specific bootloader as dangerous"
  )
  trust_option_list_key=(
    'trust-key' "Mark this bootloader's signing key as trusted"
    "${trust_option_list_nokey[@]}"
    'distrust-key' "Mark this bootloader's signing key as dangerous"
  )

  for (( idx = 0; idx < ${#drive_id_list[@]}; idx++ )); do
    if [ "${drive_id_list[idx]}" = "${drive_id}" ]; then
      drive_name="${drive_list[idx]}"
      break
    fi
  done

  if [ -z "${drive_name}" ]; then
    1>&2 printf '%s\n' "Invalid device name passed to bootloader_trust_dialog!"
    exit 1
  fi

  for boot_data_line in "${boot_data_db[@]}"; do
    IFS=':' read -r -a bit_list <<< "${boot_data_line}"
    if (( ${#bit_list[@]} < 2 )); then
      1>&2 printf '%s\n' "Invalid drive info in boot_data_db!"
      exit 1
    fi
    boot_data_drive_id="${bit_list[0]}"
    if [ "${boot_data_drive_id}" != "${drive_id}" ]; then
      continue
    fi
    IFS=';' read -r -a boot_data_sb_info <<< "${bit_list[1]}"
  done

  if (( ${#boot_data_sb_info[@]} == 0 )) \
    || [ -z "${boot_data_sb_info[0]}" ]; then
    1>&2 prinf '%s\n' "Invalid device name passed to bootloader_trust_dialog!"
    exit 1
  fi

  for sb_info_line in "${boot_data_sb_info[@]}"; do
    IFS='|' read -r -a bit_list <<< "${sb_info_line}"
    if (( ${#bit_list[@]} < 4 )); then
      1>&2 printf '%s\n' "Invalid bootloader info in boot_data_db!"
      exit 1
    fi
    sb_info_bootloader_path="${bit_list[0]}"
    if [ "${sb_info_bootloader_path}" != "${bootloader_path}" ]; then
      continue
    fi
    bootloader_key_count="${bit_list[1]}"
    if [ "${bootloader_key_count}" = '0' ]; then
      bootloader_hash="${bit_list[2]}"
      break
    else
      for (( idx = 0; idx < bootloader_key_count; idx++ )); do
        bootloader_key_list[idx]="${bit_list[(idx * 2) + 2]}"
        bootloader_key_valid_list[idx]="${bit_list[(idx * 2) + 3]}"
      done
      idx=$(( (bootloader_key_count * 2) + 2 ))
      # idx will now be one past the end of the key list
      IFS=$'\n'; echo "${bit_list[*]}"; IFS=' '
      echo "$idx"
      bootloader_hash="${bit_list[idx]}"
    fi
  done

  if [ "${bootloader_key_count}" == '0' ]; then
    prompt_msg="${bootloader_trust_nokey_text}"
    prompt_msg="${prompt_msg//XXX_BOOT_DEVICE_XXX/"${drive_name}"}"
    prompt_msg="${prompt_msg//XXX_BOOTLOADER_PATH_XXX/"${bootloader_path}"}"

    result_text="$(dialog \
      --no-collapse \
      --no-cancel \
      --title "${dialog_title}" \
      --menu "${prompt_msg}" 27 84 3 "${trust_option_list_nokey[@]}" \
      3>&1 1>&2 2>&3)"
  else
    for (( idx = 0; idx < bootloader_key_count; idx++ )); do
      for (( key_info_idx = 0; key_info_idx < ${#key_info[@]}; \
        key_info_idx++ )); do
        IFS='|' read -r -a bit_list <<< "${key_info[key_info_idx]}"
        if (( ${#bit_list[@]} < 4 )); then
          1>&2 printf '%s\n' "Invalid key info in key_info!"
          exit 1
        fi
        if [ "${bit_list[0]}" != "${bootloader_key_list[idx]}" ]; then
          continue
        fi
        bootloader_key_org="${bit_list[1]}"
        bootloader_key_ca="${bit_list[2]}"
        bootloader_key_expired="${bit_list[3]}"
      done

      if [ "${bootloader_key_valid_list[idx]}" = 'n' ]; then
        prompt_msg="${bootloader_trust_invalidkey_text}"
        prompt_msg="${prompt_msg//XXX_BOOT_DEVICE_XXX/"${drive_name}"}"
        prompt_msg="${prompt_msg//XXX_BOOTLOADER_PATH_XXX/"${bootloader_path}"}"

        result_text="$(dialog \
          --no-collapse \
          --no-cancel \
          --title "${dialog_title}" \
          --menu "${prompt_msg}" 27 84 3 "${trust_option_list_nokey[@]}" \
          3>&1 1>&2 2>&3)"

        if [ "${result_text}" = 'trust-hash' ] \
          || [ "${result_text}" = 'distrust-hash' ]; then
          break
        else
          continue
        fi
      elif [ "${bootloader_key_expired}" = 'y' ]; then
        prompt_msg="${bootloader_trust_expiredkey_text}"
        prompt_msg="${prompt_msg//XXX_BOOT_DEVICE_XXX/"${drive_name}"}"
        prompt_msg="${prompt_msg//XXX_BOOTLOADER_PATH_XXX/"${bootloader_path}"}"
        prompt_msg="${prompt_msg//XXX_KEY_FINGERPRINT_XXX/"${bootloader_key_list[idx]}"}"
        prompt_msg="${prompt_msg//XXX_KEY_ORG_XXX/"${bootloader_key_org}"}"
        prompt_msg="${prompt_msg//XXX_KEY_NAME_XXX/"${bootloader_key_ca}"}"

        result_text="$(dialog \
          --no-collapse \
          --no-cancel \
          --title "${dialog_title}" \
          --menu "${prompt_msg}" 27 84 3 "${trust_option_list_nokey[@]}" \
          3>&1 1>&2 2>&3)"

        if [ "${result_text}" = 'trust-hash' ] \
          || [ "${result_text}" = 'distrust-hash' ]; then
          break
        else
          continue
        fi
      fi

      prompt_msg="${bootloader_trust_goodkey_text}"
      prompt_msg="${prompt_msg//XXX_BOOT_DEVICE_XXX/"${drive_name}"}"
      prompt_msg="${prompt_msg//XXX_BOOTLOADER_PATH_XXX/"${bootloader_path}"}"
      prompt_msg="${prompt_msg//XXX_KEY_FINGERPRINT_XXX/"${bootloader_key_list[idx]}"}"
      prompt_msg="${prompt_msg//XXX_KEY_ORG_XXX/"${bootloader_key_org}"}"
      prompt_msg="${prompt_msg//XXX_KEY_NAME_XXX/"${bootloader_key_ca}"}"

      result_text="$(dialog \
        --no-collapse \
        --no-cancel \
        --title "${dialog_title}" \
        --menu "${prompt_msg}" 27 84 5 "${trust_option_list_key[@]}" \
        3>&1 1>&2 2>&3)"
      if [ "${result_text}" = 'trust-key' ] \
        || [ "${result_text}" = 'trust-hash' ] \
        || [ "${result_text}" = 'distrust-hash' ]; then
        break
      fi
    done
  fi

  if [ "${result_text}" = 'trust-key' ] \
    || [ "${result_text}" = 'trust-hash' ]; then
    return 0
  fi
  return 1
}

declare boot_order_idx bit_list

for (( boot_order_idx = 0; boot_order_idx < ${#boot_order[@]}; \
  boot_order_idx++ )); do
  IFS='|' read -r -a bit_list <<< "${boot_order[boot_order_idx]}"
  if bootloader_trust_dialog "${bit_list[1]}" "${bit_list[2]}"; then
    exit
  fi
done
