# Author: Hologram <support@hologram.io>
#
# Copyright 2017 - Hologram (Konekt, Inc.)
#
# LICENSE: Distributed under the terms of the MIT License
#
# test_BG96.py - This file implements unit tests for the BG96 modem interface.

from unittest.mock import patch
import pytest
import sys

from Hologram.Network.Modem.BG96 import BG96
from UtilClasses import ModemResult

sys.path.append(".")
sys.path.append("..")
sys.path.append("../..")


def mock_write(modem, message):
    return True


def mock_read(modem):
    return True


def mock_readline(modem, timeout=None, hide=False):
    return ""


def mock_open_serial_port(modem, device_name=None):
    return True


def mock_close_serial_port(modem):
    return True


def mock_detect_usable_serial_port(modem, stop_on_first=True):
    return "/dev/ttyUSB0"


@pytest.fixture
def no_serial_port(monkeypatch):
    monkeypatch.setattr(BG96, "_read_from_serial_port", mock_read)
    monkeypatch.setattr(BG96, "_readline_from_serial_port", mock_readline)
    monkeypatch.setattr(BG96, "_write_to_serial_port_and_flush", mock_write)
    monkeypatch.setattr(BG96, "openSerialPort", mock_open_serial_port)
    monkeypatch.setattr(BG96, "closeSerialPort", mock_close_serial_port)
    monkeypatch.setattr(BG96, "detect_usable_serial_port", mock_detect_usable_serial_port)


def test_init_BG96_no_args(no_serial_port):
    modem = BG96()
    assert modem.timeout == 1
    assert modem.socket_identifier == 0
    assert modem.chatscript_file.endswith("/chatscripts/default-script")
    assert modem._at_sockets_available


@patch.object(BG96, "set")
@patch.object(BG96, "command")
@patch.object(BG96, "_is_pdp_context_active")
def test_close_socket(mock_pdp, mock_command, mock_set, no_serial_port):
    modem = BG96()
    modem.socket_identifier = 1
    mock_set.return_value = (ModemResult.OK, None)
    mock_command.return_value = (ModemResult.OK, None)
    mock_pdp.return_value = True
    modem.close_socket()
    mock_set.assert_called_with("+QIACT", "0", timeout=30)
    mock_command.assert_called_with("+QICLOSE", 1)
