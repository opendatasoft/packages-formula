# -*- coding: utf-8 -*-
# vim: ft=sls

{%- from "packages/map.jinja" import packages with context %}

{%- set req_states = packages.pkgs.required.states %}
{%- set req_packages = packages.pkgs.required.pkgs %}
{%- set held_packages = packages.pkgs.held %}
{%- set wanted_packages = packages.pkgs.wanted %}
{%- set unwanted_packages = packages.pkgs.unwanted %}

{%- if held_packages or wanted_packages %}
  {%- if req_states %}
include:
    {%- for dep in req_states %}
  - {{ dep }}
    {%- endfor %}
  {%- endif %}

### PRE-REQ PKGS (without these, some of the WANTED PKGS will fail to install)
pkg_req_pkgs:
  pkg.installed:
    {%- if req_packages is mapping %}
    - pkgs:
      {%- for p, v in req_packages.items() %}
        {%- if v %}
      - {{ p }}: {{ v }}
        {%- else %}
      - {{ p }}
        {%- endif %}
      {%- endfor %}
    {%- else %}
    - pkgs: {{ req_packages | json }}
    {%- endif %}
    {%- if req_states %}
    - require:
      {%- for dep in req_states %}
      - sls: {{ dep }}
      {%- endfor %}
    {%- endif %}
    - retry: {{ packages.retry_options|json }}

  {%- if held_packages != {} %}
held_pkgs:
  pkg.installed:
    {%- if held_packages is mapping %}
    - pkgs:
      {%- for p, v in held_packages.items() %}
        {%- if v %}
      - {{ p }}: {{ v }}
        {%- else %}
      - {{ p }}
        {%- endif %}
      {%- endfor %}
    {%- else %}
    - pkgs: {{ held_packages | json }}
    {%- endif %}
    {%- if grains['os_family'] not in ['Suse'] %}
    - hold: true
    - update_holds: true
    {%- endif %}
    - require:
      - pkg: pkg_req_pkgs
        {%- for dep in req_states %}
      - sls: {{ dep }}
        {%- endfor %}
    - retry: {{ packages.retry_options|json }}
  {%- endif %}

wanted_pkgs:
  pkg.installed:
    {%- if wanted_packages is mapping %}
    - pkgs:
      {%- for p, v in wanted_packages.items() %}
        {%- if v %}
      - {{ p }}: {{ v }}
        {%- else %}
      - {{ p }}
        {%- endif %}
      {%- endfor %}
    {%- else %}
    - pkgs: {{ wanted_packages | json }}
    {%- endif %}
    {%- if grains['os_family'] not in ['Suse'] %}
    - hold: false
    {%- endif %}
    - require:
      - pkg: pkg_req_pkgs
      {%- if req_states %}
        {%- for dep in req_states %}
      - sls: {{ dep }}
        {%- endfor %}
      {%- endif %}
    - retry: {{ packages.retry_options|json }}

unwanted_pkgs:
  pkg.purged:
    {%- if unwanted_packages is mapping %}
    - pkgs:
      {%- for p, v in unwanted_packages.items() %}
      - {{ p }}
      {%- endfor %}
    {%- else %}
    - pkgs: {{ unwanted_packages | json }}
    {%- endif %}

{%- endif %}
