//
//  CalorieTrackerTableViewController.swift
//  Calorie Tracker
//
//  Created by patelpra on 6/13/20.
//  Copyright © 2020 Crus Technologies. All rights reserved.
//

import UIKit
import CoreData
import SwiftChart

extension Notification.Name {
    static var updateChart = Notification.Name("updateChart")
}

class CalorieTrackerTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    lazy var fetchedResultsController: NSFetchedResultsController<Calorie> = {
        let fetechRequest: NSFetchRequest<Calorie> = Calorie.fetchRequest()
        fetechRequest.sortDescriptors = [NSSortDescriptor(key: "created", ascending: true), NSSortDescriptor(key: "created", ascending: true)]
        
        let moc = CoreDataStack.shared.mainContext
        let frc = NSFetchedResultsController(fetchRequest: fetechRequest, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        
        frc.delegate = self
        
        try! frc.performFetch()
        return frc
        
    }()
    
    @IBOutlet weak var chartUIView: UIView!
    
    let calorieController = CalorieController()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateChart(notification:)), name: .updateChart, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.post(name: .updateChart, object: self)
    }
    
    @objc func updateChart(notification: Notification) {
        let chart = Chart(frame: chartUIView.frame)
        var data: [Double] = []
        for calorie in fetchedResultsController.fetchedObjects! {
            print(calorie.calories as Any)
            data.append(Double(calorie.calories!)!)
        }
        let series = ChartSeries(data)
        series.area = true
        chart.add(series)
        self.chartUIView.subviews.forEach ({ $0.removeFromSuperview() })
        self.chartUIView.addSubview(chart)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.fetchedResultsController.sections?.count ?? 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalorieCell", for: indexPath)

        let calorie = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = "Calories: \(calorie.calories ?? "0")"
        
        cell.detailTextLabel?.text = calorie.date

        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if editingStyle == .delete {
                let calorie = self.fetchedResultsController.object(at: indexPath)
                self.calorieController.deleteCalorie(withCalorie: calorie)
                self.tableView.reloadData()
            }
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    // Sections
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    // Rows
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        default:
            break
        }
    }
    @IBAction func addCalorieButtonTapped(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Add Calorie Intake", message: "Enter the amount of calories in the field", preferredStyle: .alert)
        alertController.addTextField { (texfield : UITextField!) -> Void
            in
            texfield.placeholder = "Calories:"
        }
        let submitAction = UIAlertAction(title: "Submit", style: UIAlertAction.Style.default, handler: { alert -> Void in
            let firstTextField = alertController.textFields![0] as
                UITextField
            guard let calorieCount = firstTextField.text else { return }
            self.calorieController.createdCalorie(withCalorieCount: calorieCount)
            NotificationCenter.default.post(name: .updateChart, object: self)
            self.tableView.reloadData()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {(action : UIAlertAction!) -> Void in })
        
        alertController.addAction(cancelAction)
        alertController.addAction(submitAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
}
