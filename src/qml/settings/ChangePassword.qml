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

import "../elements"

Kirigami.Page {
	topPadding: 0

	Controls.BusyIndicator {
		id: busyIndicator
		visible: false
		anchors.centerIn: parent
		width: 60
		height: 60
	}

	ColumnLayout {
		id: content
		anchors.fill: parent
		spacing: 0

		Kirigami.Heading {
			Layout.alignment: Qt.Top
			level: 2
			text: qsTr("Change password")
		}

		Kirigami.FormLayout {
			Layout.fillWidth: true
			Controls.TextField {
				id: oldPassword
				echoMode: TextInput.Password
				selectByMouse: true
				Kirigami.FormData.label: qsTr("Current password:")
			}
			Controls.TextField {
				id: password1
				echoMode: TextInput.Password
				selectByMouse: true
				Kirigami.FormData.label: qsTr("New password:")
			}
			Controls.TextField {
				id: password2
				echoMode: TextInput.Password
				selectByMouse: true
				Kirigami.FormData.label: qsTr("New password (repeat):")
			}
		}

		Kirigami.InlineMessage {
			type: Kirigami.MessageType.Warning
			visible: password1.text !== password2.text
			text: qsTr("New passwords do not match.")
			anchors.left: parent.left
			anchors.right: parent.right
			showCloseButton: true
		}

		Kirigami.InlineMessage {
			id: currentPasswordInvalidMessage
			visible: false
			type: Kirigami.MessageType.Warning
			text: qsTr("Current password is invalid.")
			anchors.left: parent.left
			anchors.right: parent.right
			showCloseButton: true
		}

		Kirigami.InlineMessage {
			visible: Kaidan.connectionState !== Enums.StateConnected
			type: Kirigami.MessageType.Error
			text: qsTr("You need to be connected to change your password.")
			anchors.left: parent.left
			anchors.right: parent.right
		}

		Controls.Label {
			Layout.fillWidth: true
			text: qsTr("After changing your password, you will need to reenter "
					 + "it on all your other devices.")
			textFormat: Text.PlainText
			wrapMode: Text.WordWrap
		}

		RowLayout {
			Layout.fillWidth: true
			Layout.alignment: Qt.AlignBottom

			Button {
				text: qsTr("Cancel")
				onClicked: stack.pop()
				Layout.fillWidth: true
			}

			Button {
				text: qsTr("Change")
				Layout.fillWidth: true
				enabled: {
					password1.text === password2.text && password1.text !== ""
							&& Kaidan.connectionState === Enums.StateConnected
				}
				onClicked: {
					if (oldPassword.text !== Kaidan.password) {
						currentPasswordInvalidMessage.visible = true
						return
					}

					Kaidan.changePassword(password1.text)
					content.visible = false
					busyIndicator.visible = true
				}
			}
		}
	}

	function handleChangeResult() {
		busyIndicator.visible = false
		stack.pop()
	}

	Component.onCompleted: {
		Kaidan.passwordChangeSucceeded.connect(handleChangeResult)
		Kaidan.passwordChangeFailed.connect(handleChangeResult)
	}
	Component.onDestruction: {
		Kaidan.passwordChangeSucceeded.disconnect(handleChangeResult)
		Kaidan.passwordChangeFailed.disconnect(handleChangeResult)
	}
}
