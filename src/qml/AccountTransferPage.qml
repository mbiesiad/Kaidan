/*
 *  Kaidan - A user-friendly XMPP client for every device!
 *
 *  Copyright (C) 2016-2020 Kaidan developers and contributors
 *  (see the LICENSE file for a full list of copyright authors)
 *
 *  Kaidan is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  In addition, as a special exception, the author of Kaidan gives
 *  permission to link the code of its release with the OpenSSL
 *  project's "OpenSSL" library (or with modified versions of it that
 *  use the same license as the "OpenSSL" library), and distribute the
 *  linked executables. You must obey the GNU General Public License in
 *  all respects for all of the code used other than "OpenSSL". If you
 *  modify this file, you may extend this exception to your version of
 *  the file, but you are not obligated to do so.  If you do not wish to
 *  do so, delete this exception statement from your version.
 *
 *  Kaidan is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with Kaidan.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import QtQuick.Controls 2.12 as Controls
import QtQuick.Layouts 1.12
import org.kde.kirigami 2.8 as Kirigami

import im.kaidan.kaidan 1.0

import "elements"

/**
 * This page shows the user's credentials as a QR code or as cleartext, which allows the user to log in on another device.
 */
Kirigami.Page {
	id: root
	title: qsTr("Transfer account to another device")
	leftPadding: 0
	rightPadding: 0
	topPadding: 0
	bottomPadding: 0

	QrCodeGenerator {
		id: qrCodeGenerator
	}

	ColumnLayout {
		z: 1
		anchors.margins: 18
		anchors.top: parent.top
		anchors.left: parent.left
		anchors.right: parent.right
		anchors.bottom: parent.bottom

		CenteredAdaptiveText {
			id: explanation
			text: qsTr("Scan the QR code or enter the credentials as text on another device to log in on it.\n\nAttention:\nNever show this QR code to anyone else. It would allow unlimited access to your account!")
			width: parent.width
			Layout.topMargin: 10
			scaleFactor: 1.5
		}

		// placeholder
		Item {
			Layout.fillHeight: true
		}

		Kirigami.Icon {
			id: qrCode
			width: parent.width
			height: width
			visible: false
			source: visible ? qrCodeGenerator.generateLoginUriQrCode(width) : ""
			Layout.fillWidth: true
			Layout.fillHeight: true
		}

		Kirigami.FormLayout {
			id: cleartext
			visible: false

			Controls.Label {
				text: Kaidan.jid
				Kirigami.FormData.label: qsTr("Chat address:")
			}

			Controls.Label {
				text: Kaidan.password
				Kirigami.FormData.label: qsTr("Password:")
			}
		}

		// placeholder
		Item {
			Layout.fillHeight: true
		}

		ColumnLayout {
			Layout.alignment: Qt.AlignHCenter
			Layout.maximumWidth: largeButtonWidth

			// button for showing or hiding the credentials as a QR code
			CenteredAdaptiveHighlightedButton {
				label.text: checked ? qsTr("Hide QR code") : qsTr("Show as QR code")
				checkable: true

				// If that was not used, this button would change its label text but not its checked state when the button for showing the cleartext is clicked right after it.
				checked: qrCode.visible

				onClicked: {
					if (qrCode.visible) {
						qrCode.visible = false
						cleartext.visible = false
						explanation.visible = true
					} else {
						qrCode.visible = true
						cleartext.visible = false
						explanation.visible = false
					}
				}
			}

			// button for showing or hiding the credentials as cleartext
			CenteredAdaptiveButton {
				label.text: checked ? qsTr("Hide text") : qsTr("Show as text")
				checkable: true

				// If that was not used, this button would change its label text but not its checked state when the button for showing the QR code is clicked right after it.
				checked: cleartext.visible

				onClicked: {
					if (cleartext.visible) {
						cleartext.visible = false
						qrCode.visible = false
						explanation.visible = true
					} else {
						cleartext.visible = true
						qrCode.visible = false
						explanation.visible = false
					}
				}
			}
		}
	}
}
