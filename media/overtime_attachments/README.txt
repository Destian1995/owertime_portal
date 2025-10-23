- name: Ensure any existing exporter service is removed
  ansible.windows.win_service:
    name: "{{ generic_exporter_name_service }}"
    state: absent
  failed_when: false

- name: Register (or re‑register) Windows Exporter as a service
  ansible.windows.win_service:
    name: "{{ generic_exporter_name_service }}"
    display_name: "{{ generic_exporter_name_service }}"
    binary_path_name: >-
      "{{ generic_exporter_bin_dir }}\{{ generic_exporter_name_service }}.exe
      --config.file={{ generic_exporter_config_path }}"
    start_mode: auto
    state: present
  register: service_registered

- name: Start Windows Exporter service
  ansible.windows.win_service:
    name: "{{ generic_exporter_name_service }}"
    state: started
    start_mode: auto
  when: service_registered.changed or config_changed.changed
