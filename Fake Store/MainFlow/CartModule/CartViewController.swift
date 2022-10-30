//
//  CartViewController.swift
//  Fake Store
//
//  Created by Антон Голубейков on 29.10.2022.
//

import UIKit

final class CartViewController: UIViewController {

    // MARK: - Constants

    private let cartProductCell = "\(CartProductTableViewCell.self)"

    // MARK: - IBOutlets

    @IBOutlet weak var cartTableView: UITableView!
    @IBOutlet weak var makeOrderButtonLabel: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Private properties

    private let productsInCart = CartService.shared

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        productsInCart.loadProducts()
        configureAppearance()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    // MARK: - Actions

    @IBAction func makeOrderButtonAction(_ sender: Any) {
    }

}

// MARK: - Private extension

private extension CartViewController {

    func configureAppearance() {
        configureModel()
        configureButton()
        configureTableView()
        setGradientBackground()
    }

    func configureNavigationBar() {
        navigationItem.title = "Корзина"
    }

    func configureTableView() {
        cartTableView.backgroundColor = ColorsStorage.clear
        cartTableView.dataSource = self
        cartTableView.allowsSelection = false
        cartTableView.register(UINib(nibName: cartProductCell, bundle: .main), forCellReuseIdentifier: cartProductCell)
    }

    func configureButton() {
        makeOrderButtonLabel.backgroundColor = ColorsStorage.orange
        makeOrderButtonLabel.setTitle("Сделать заказ", for: .normal)
        makeOrderButtonLabel.tintColor = ColorsStorage.black
    }

    func setGradientBackground() {
        let colorTop = ColorsStorage.white.cgColor
        let colorBottom = ColorsStorage.gradientBlue.cgColor

        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    func configureModel() {
        productsInCart.didProductsFetchErrorHappened = { [weak self] in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                self.activityIndicator.isHidden = true
                let textForSnackBar = AllCatalogModel.errorDescription
                let model = SnackbarModel(text: textForSnackBar)
                let snackbar = SnackbarView(model: model, viewController: self)
                snackbar.showSnackBar()
            }
        }
        productsInCart.didProductsUpdated = { [weak self] in
            DispatchQueue.main.async {
                guard let `self` = self else { return }
                self.activityIndicator.isHidden = true
                self.cartTableView.reloadData()
             }
        }
    }

}

// MARK: - Table view data source

extension CartViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        productsInCart.productsInCart.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = cartTableView.dequeueReusableCell(withIdentifier: cartProductCell) as? CartProductTableViewCell else { return UITableViewCell() }
        cell.configureCell(model: productsInCart.productsInCart[indexPath.row])
        return cell
    }

}
