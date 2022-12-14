//
//  CatalogViewController.swift
//  Fake Store
//
//  Created by Антон Голубейков on 22.10.2022.
//

import UIKit

final class CatalogViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet private weak var catalogTableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!

    // MARK: - Views

    private let refreshControl = UIRefreshControl()

    // MARK: - Private properties

    private let catalogModel = AllCatalogModel.shared
    private var catalog = AllCatalogModel.shared.getCatalog(for: "")
    private let cellReuseIndentifier = "CatalogCell"
    private let navigationBarTitle = "Каталог"
    private let searchBarPlaceholder = "Поиск"

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        catalogModel.loadCatalog()
        configureAppearance()
        hideKeyboardWhenTapped()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
        setGradientBackground()
        subcribeToNotificationCenter()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromNotificationCenter()
    }

}

// MARK: - Private methods

private extension CatalogViewController {

    func configureAppearance() {
        configureTableView()
        configureModel()
        configurePullToRefresh()
        configureSearchBar()
        configureViewStyle()
    }

    func configureTableView() {
        catalogTableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIndentifier)
        catalogTableView.delegate = self
        catalogTableView.dataSource = self
    }

    func configureNavigationBar() {
        navigationItem.title = navigationBarTitle
    }

    func configureViewStyle() {
        view.backgroundColor = ColorsStorage.backgroundBlue
    }

    func setGradientBackground() {
        let colorTop = ColorsStorage.white.cgColor
        let colorBottom = ColorsStorage.gradientBlue.cgColor

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = self.catalogTableView.bounds
        let backgroundView = UIView(frame: catalogTableView.bounds)
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        self.catalogTableView.backgroundView = backgroundView

    }

    func configureModel() {
        catalogModel.didCatalogFetchErrorHappened = { [weak self] in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                self.activityIndicator.isHidden = true
                let textForSnackBar = AllCatalogModel.errorDescription
                let model = SnackbarModel(text: textForSnackBar)
                let snackbar = SnackbarView(model: model, viewController: self)
                snackbar.showSnackBar()
            }
        }
        catalogModel.didCatalogUpdated = { [weak self] in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                self.activityIndicator.isHidden = true
                self.catalog = self.catalogModel.getCatalog(for: "")
                self.catalogTableView.reloadData()
             }
        }
    }

    func configureSearchBar() {
        searchBar.placeholder = searchBarPlaceholder
        searchBar.barTintColor = ColorsStorage.backgroundBlue
        searchBar.delegate = self
    }

    func configurePullToRefresh() {
        refreshControl.addTarget(self, action: #selector(self.pullToRefresh(_:)), for: .valueChanged)
        refreshControl.tintColor = ColorsStorage.lightGray
        refreshControl.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        catalogTableView.addSubview(refreshControl)
    }

    @objc func pullToRefresh(_ sender: AnyObject) {
        self.catalogModel.loadCatalog()
        refreshControl.endRefreshing()
    }

}

// MARK: - Table View

extension CatalogViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        catalog.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = catalogTableView.dequeueReusableCell(withIdentifier: cellReuseIndentifier, for: indexPath)
        cell.textLabel?.text = catalog[indexPath.row].title
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = catalog[indexPath.row].title
        let productsController = ProductsViewController(category: category)
        navigationController?.pushViewController(productsController, animated: true)
        catalogTableView.deselectRow(at: indexPath, animated: true)
    }

}

//MARK: - Handle keyboard's show-up methods

extension CatalogViewController {
    //Скрытие клавиатуры по тапу
    func hideKeyboardWhenTapped() {
        let hideKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        hideKeyboardGesture.cancelsTouchesInView = false
        view?.addGestureRecognizer(hideKeyboardGesture)
    }

    @objc func hideKeyboard() {
        self.view?.endEditing(true)
    }
    func subcribeToNotificationCenter() {
        //Подписываемся на два уведомления: одно приходит при появлении клавиатуры. #selector(self.keyboardWasShown) - функция, которая выполняется после получения события.
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWasShown), name: UIResponder.keyboardWillShowNotification, object: nil)
        // Второе — когда она пропадает
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillBeHidden(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    func unsubscribeFromNotificationCenter() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    //Функции, которые вызываются после появления / исчезновения клавиатуры (нужно чтобы клавиатура не залезала на поля ввода)
    @objc func keyboardWasShown(notification: Notification) {
        // Получаем размер клавиатуры
        let info = notification.userInfo! as NSDictionary
        let kbSize = (info.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue).cgRectValue.size
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
                as? Double else {
            return
        }
        // Добавляем отступ, равный размеру клавиатуры (80 это размер таббара, на данном этапе упрощено константой, целевая реализация - расчитывать высоту topTabBarController
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut]) { [weak self] in
            self?.bottomConstraint.constant = -kbSize.height + 80
            self?.view.layoutIfNeeded()
        }


    }
    //Когда клавиатура исчезает
    @objc func keyboardWillBeHidden(notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
                as? Double else {
            return
        }
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut]) { [weak self] in
            self?.bottomConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }
    }

}

extension CatalogViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        searchBar.resignFirstResponder()
        if !searchText.isEmpty {
            catalog = catalogModel.getCatalog(for: searchText.lowercased())
            catalogTableView.reloadData()
        } else {
            catalog = catalogModel.getCatalog(for: "")
            catalogTableView.reloadData()
        }
    }
    
}
