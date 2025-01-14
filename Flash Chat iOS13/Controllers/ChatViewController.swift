//
//  ChatViewController.swift
//  Flash Chat iOS13
//
//  Created by Angela Yu on 21/10/2019.
//  Copyright © 2019 Angela Yu. All rights reserved.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    let db = Firestore.firestore()
    var ref : DocumentReference? = nil
    var messages : [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let attrs = [
            NSAttributedString.Key.foregroundColor: UIColor.red,
            NSAttributedString.Key.font: UIFont(name: "Georgia-Bold", size: 24)!
        ]
        UINavigationBar.appearance().titleTextAttributes = attrs
        tableView.dataSource = self
        navigationItem.hidesBackButton = true
        
        self.tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        //메시지창을 만드는 방법을 꼭 복습하자!!(쌈이랑 고기로 생각해보기!)
        loadMessage()
    }
    
    func loadMessage(){
        db.collection(K.FStore.collectionName)
          .order(by: K.FStore.dateField)
          .addSnapshotListener { (querySnapshot, error) in
            self.messages = []
            if let e = error{
                print("There are some problem retrieving from Firestore. \(e)")
            } else {
                if let snapShotDocument = querySnapshot?.documents {
                    for doc in snapShotDocument {
                        let data = doc.data()
                        if let sender = data[K.FStore.senderField] as? String,
                            let messageBody = data[K.FStore.bodyField] as? String{
                            let newMessage = Message(sender: sender, body: messageBody)
                            self.messages.append(newMessage)
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                let indexPath = IndexPath(row: self.messages.count-1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true )
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email{
            self.messageTextfield.text = ""
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.senderField : messageSender,
                K.FStore.bodyField : messageBody,
                K.FStore.dateField : Date().timeIntervalSince1970
            ]) { (error) in
                if let e = error {
                    print("There was an issue saving data in FireStore \(e)")
                } else{
                    print("Successfully saved data")
                }
            }
        }
        //MARK: - 내가 만든 부분
        //        ref = db.collection("tls1gy2rms3@naver.com").addDocument(data: [
        //            "body" : messageTextfield.text ?? ""
        //        ]) { err in
        //            if let err = err {
        //                print("Error adding document: \(err)")
        //            } else {
        //                print("Document added with ID: \(self.ref!.documentID)")
        //            }
        //        }
        //
        //        db.collection("tls1gy2rms3@naver.com").getDocuments() { (querySnapshot, err) in
        //            if let err = err {
        //                print("Error getting documents: \(err)")
        //            } else {
        //                for document in querySnapshot!.documents {
        //                    if self.ref!.documentID == document.documentID{
        //                        var sender = "tls1gy2rms3@naver.com"
        //                        var contents = document.data()["body"]!
        //                        var madedMessage = Message(sender: sender, body: contents as! String)
        //                        self.message.append(madedMessage)
        //                        self.tableView.reloadData()
        //                    }
        //                }
        //            }
        //        }
        //        messageTextfield.text = ""
    }
    
    @IBAction func LogOutPressed(_ sender: UIBarButtonItem) {
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
}

extension ChatViewController : UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    //메시지창을 만드는 방법을 꼭 복습하자!!(쌈이랑 고기로 생각해보기!)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as!MessageCell
        cell.label.text = message.body
//         This is a message from current user.
        if message.sender == Auth.auth().currentUser?.email {
             cell.leftImageView.isHidden = true
             cell.rightImageView.isHidden = false
             cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
             cell.label.textColor = UIColor(named: K.BrandColors.purple)
        }else{
//         This is a message from current user.
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        return cell
    }
}

