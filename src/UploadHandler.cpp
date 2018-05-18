/*
 *  Kaidan - A user-friendly XMPP client for every device!
 *
 *  Copyright (C) 2018 Kaidan developers and contributors
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

#include "UploadHandler.h"
#include "QtHttpUploader.h"
#include "MessageHandler.h"
// gloox
#include <gloox/message.h>
#include "gloox-extensions/httpuploadmanager.h"
#include "gloox-extensions/reference.h"
#include "gloox-extensions/sims.h"
#include "gloox-extensions/processinghints.h"
#include "gloox-extensions/jinglefile.h"
#include "gloox-extensions/hash.h"
// Qt
#include <QMimeDatabase>
#include <QMimeType>
#include <QDateTime>
#include <QDebug>

UploadHandler::UploadHandler(gloox::Client *client, MessageHandler *msgHandler,
                             MessageModel *msgModel, QObject *parent)
	: QObject(parent), client(client), msgHandler(msgHandler), msgModel(msgModel)
{
	manager = new gloox::HttpUploadManager(client);
	uploader = new QtHttpUploader(manager);

	manager->registerHttpUploadHandler(this);
}

void UploadHandler::uploadFile(QString jid, QString filePath)
{
	// get MIME-type
	QMimeDatabase mimeDb;
	QMimeType mimeType = mimeDb.mimeTypeForFile(filePath);
	QString mimeTypeStr = mimeType.name();
	qDebug() << filePath;

	int id = manager->uploadFile(filePath.toStdString(), true,
	                             mimeTypeStr.toStdString());

	if (id < 0) {
		// failure
		// TODO: send passive notification
	} else {
		// save for later processing/sending
		MediaSharingMeta meta;
		meta.jid = jid;
		meta.msgId = client->getID();

		mediaShares[id] = meta;

		QString body = "";
		msgHandler->addMessageToDb(
			jid, body, QString::fromStdString(meta.msgId),
			getMessageType(mimeType), filePath
		);
	}
}

void UploadHandler::handleUploadFailed(int id, gloox::HttpUploadError error,
                                       const std::string &text,
                                       const std::string &stamp)
{
	qDebug() << "[client] A file upload has failed.";
}

void UploadHandler::handleUploadFinished(int id, std::string &name,
                                         std::string &getUrl,
                                         std::string &contentType,
                                         unsigned long &size)
{
	qDebug() << "[client] A file upload has finished.";
	// save new information to database
	MessageModel::Message msg;
	msg.mediaUrl = QString::fromStdString(getUrl);
	msg.mediaContentType = QString::fromStdString(contentType);
	msg.mediaSize = size;
	// TODO: mediaLastModified

	emit msgModel->updateMessageRequested(
		QString::fromStdString(mediaShares[id].msgId), msg
	);

	// TODO: send SIMS message (and optionally also create jingle object)
	// for now only send a normal text message with the get URL.
	QString body = QString::fromStdString(getUrl);
	msgHandler->sendOnlyMessage(mediaShares[id].jid, body, mediaShares[id].msgId);

	// the media meta isn't needed anymore, so delete it
	mediaShares.remove(id);
}

void UploadHandler::handleUploadProcess(int id, long unsigned int sent,
                                        long unsigned int total)
{
}

void UploadHandler::handleUploadServiceRemoved(const gloox::JID &jid)
{
}

void UploadHandler::handleUploadServiceAdded(const gloox::JID &jid,
                                             unsigned long maxFileSize)
{
}

void UploadHandler::handleFileSizeLimitChanged(unsigned long maxFileSize)
{
}

MessageType UploadHandler::getMessageType(QMimeType& type)
{
	if (type.inherits("image/jpeg") || type.inherits("image/png") ||
	    type.inherits("image/gif"))
		return MessageType::MessageImage;
	else if (type.inherits("audio/flac") || type.inherits("audio/mp4") ||
	         type.inherits("audio/ogg") || type.inherits("audio/wav") ||
	         type.inherits("audio/mpeg") || type.inherits("audio/webm"))
		return MessageType::MessageAudio;
	else if (type.inherits("video/mpeg") || type.inherits("video/x-msvideo") ||
	         type.inherits("video/quicktime") || type.inherits("video/mp4") ||
	         type.inherits("video/x-matroska"))
		return MessageType::MessageVideo;
	else if (type.inherits("text/plain"))
		return MessageType::MessageDocument;
	return MessageType::MessageFile;
}