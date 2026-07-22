#!/usr/bin/env python3
"""
Entry point for the MutInt assembled project.
"""
import os
import sys


def main():
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, BASE_DIR)

    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings_local')
    from django.core.management import execute_from_command_line
    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
