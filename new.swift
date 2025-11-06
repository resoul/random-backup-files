import AsyncDisplayKit
import Combine
import UIKit
import Foundation

// MARK: - ============================================
// MARK: - VIEW STATE & VIEW MODELS
// MARK: - ============================================

enum UserDomainViewState {
   case idle
   case loading
   case loaded
   case error(String)
   case deleting(index: Int)
   case verifying(index: Int)
}

struct UserDomainCellViewModel {
   let uuid: UUID
   let domain: String
   let state: String
   let stateColor: String
   let createdAt: String
   let dnsRecords: [DNSRecordViewModel]
   let canDelete: Bool
   let canVerify: Bool

   struct DNSRecordViewModel {
       let type: String
       let name: String
       let value: String
       let isVerified: Bool
   }
}

// MARK: - ============================================
// MARK: - PRESENTER PROTOCOL & DELEGATE
// MARK: - ============================================

protocol UserDomainPresenter: AnyObject {
   var viewStatePublisher: AnyPublisher<UserDomainViewState, Never> { get }
   var itemsPublisher: AnyPublisher<[UserDomainCellViewModel], Never> { get }

   func viewDidLoad()
   func loadMoreIfNeeded(currentIndex: Int)
   func didSelectItem(at index: Int)
   func didRequestDelete(at index: Int)
   func didRequestVerification(at index: Int)
   func didConfirmDelete(at index: Int)
}

protocol UserDomainPresenterDelegate: AnyObject {
   func presenterDidSelectDomain(_ domain: UserDomain)
   func presenterDidRequestDeleteConfirmation(for domain: UserDomain, at index: Int)
   func presenterDidDeleteDomain()
   func presenterDidVerifyDomain(success: Bool)
}

// MARK: - ============================================
// MARK: - PRESENTER IMPLEMENTATION
// MARK: - ============================================

final class UserDomainPresenterImpl: UserDomainPresenter {

   // MARK: - Publishers
   private let viewStateSubject = CurrentValueSubject<UserDomainViewState, Never>(.idle)
   private let itemsSubject = CurrentValueSubject<[UserDomainCellViewModel], Never>([])

   var viewStatePublisher: AnyPublisher<UserDomainViewState, Never> {
       viewStateSubject.eraseToAnyPublisher()
   }

   var itemsPublisher: AnyPublisher<[UserDomainCellViewModel], Never> {
       itemsSubject.eraseToAnyPublisher()
   }

   // MARK: - Dependencies
   private let viewModel: UserDomainViewModel
   private var cancellables = Set<AnyCancellable>()

   // MARK: - State
   private var domains: [UserDomain] = []
   private var totalCount: Int = 0
   private var isLoadingMore = false

   // MARK: - Callbacks
   weak var delegate: UserDomainPresenterDelegate?

   init(viewModel: UserDomainViewModel) {
       self.viewModel = viewModel
       setupBindings()
   }

   // MARK: - Setup
   private func setupBindings() {
       viewModel.items
           .sink { [weak self] domains in
               self?.handleNewDomains(domains)
           }
           .store(in: &cancellables)

       viewModel.totalItems
           .sink { [weak self] total in
               self?.totalCount = total
           }
           .store(in: &cancellables)
   }

   // MARK: - Public Methods
   func viewDidLoad() {
       loadInitialData()
   }

   func loadMoreIfNeeded(currentIndex: Int) {
       let threshold = 3
       let shouldLoadMore = currentIndex >= domains.count - threshold
       let hasMoreItems = domains.count < totalCount

       guard shouldLoadMore, hasMoreItems, !isLoadingMore else { return }

       loadMoreData()
   }

   func didSelectItem(at index: Int) {
       guard index < domains.count else { return }
       let domain = domains[index]
       delegate?.presenterDidSelectDomain(domain)
   }

   func didRequestDelete(at index: Int) {
       guard index < domains.count else { return }
       let domain = domains[index]
       delegate?.presenterDidRequestDeleteConfirmation(for: domain, at: index)
   }

   func didRequestVerification(at index: Int) {
       guard index < domains.count else { return }
       verifyDomain(at: index)
   }

   func didConfirmDelete(at index: Int) {
       guard index < domains.count else { return }
       deleteDomain(at: index)
   }

   // MARK: - Private Methods
   private func loadInitialData() {
       viewStateSubject.send(.loading)

       Task {
           do {
               try await viewModel.fetchListings()
               await MainActor.run {
                   viewStateSubject.send(.loaded)
               }
           } catch {
               await MainActor.run {
                   viewStateSubject.send(.error(error.localizedDescription))
               }
           }
       }
   }

   private func loadMoreData() {
       isLoadingMore = true

       Task {
           do {
               try await viewModel.fetchListings()
               await MainActor.run {
                   isLoadingMore = false
               }
           } catch {
               await MainActor.run {
                   isLoadingMore = false
                   viewStateSubject.send(.error(error.localizedDescription))
               }
           }
       }
   }

   private func deleteDomain(at index: Int) {
       let domain = domains[index]
       viewStateSubject.send(.deleting(index: index))

       Task {
           do {
               try await viewModel.delete(domainUuid: domain.uuid)
               await MainActor.run {
                   domains.remove(at: index)
                   totalCount -= 1
                   updateCellViewModels()
                   viewStateSubject.send(.loaded)
                   delegate?.presenterDidDeleteDomain()
               }
           } catch {
               await MainActor.run {
                   viewStateSubject.send(.error("Failed to delete domain"))
               }
           }
       }
   }

   private func verifyDomain(at index: Int) {
       let domain = domains[index]
       viewStateSubject.send(.verifying(index: index))

       Task {
           do {
               let updatedDomain = try await viewModel.verify(userDomain: domain)
               await MainActor.run {
                   domains[index] = updatedDomain
                   updateCellViewModels()
                   viewStateSubject.send(.loaded)

                   if updatedDomain.state == .verified {
                       delegate?.presenterDidVerifyDomain(success: true)
                   } else {
                       delegate?.presenterDidVerifyDomain(success: false)
                   }
               }
           } catch {
               await MainActor.run {
                   viewStateSubject.send(.error("Failed to verify domain"))
               }
           }
       }
   }

   private func handleNewDomains(_ newDomains: [UserDomain]) {
       domains.append(contentsOf: newDomains)
       updateCellViewModels()
   }

   private func updateCellViewModels() {
       let user = viewModel.getCurrentUser()
       let cellViewModels = domains.map { domain in
           mapDomainToCellViewModel(domain, user: user)
       }
       itemsSubject.send(cellViewModels)
   }

   private func mapDomainToCellViewModel(_ domain: UserDomain, user: User?) -> UserDomainCellViewModel {
       return UserDomainCellViewModel(
           uuid: domain.uuid,
           domain: domain.domain,
           state: domain.state.rawValue.capitalized,
           stateColor: getStateColor(domain.state),
           createdAt: formatDate(domain.createdAt),
           dnsRecords: mapDNSRecords(domain.dnsRecords),
           canDelete: true,
           canVerify: domain.state != .verified
       )
   }

   private func mapDNSRecords(_ records: [DNSRecord]) -> [UserDomainCellViewModel.DNSRecordViewModel] {
       records.map { record in
           UserDomainCellViewModel.DNSRecordViewModel(
               type: record.type,
               name: record.name,
               value: record.value,
               isVerified: record.isVerified
           )
       }
   }

   private func getStateColor(_ state: UserDomainState) -> String {
       switch state {
       case .verified:
           return "#4CAF50"
       case .pending:
           return "#FF9800"
       case .failed:
           return "#F44336"
       }
   }

   private func formatDate(_ date: Date) -> String {
       let formatter = DateFormatter()
       formatter.dateStyle = .medium
       formatter.timeStyle = .short
       return formatter.string(from: date)
   }
}

// MARK: - ============================================
// MARK: - DATA SOURCE
// MARK: - ============================================

protocol UserDomainDataSourceProtocol: ASCollectionDataSource {
   func configure(with items: [UserDomainCellViewModel])
   func getItemsCount() -> Int
}

final class UserDomainDataSource: NSObject, UserDomainDataSourceProtocol {

   // MARK: - Properties
   private var items: [UserDomainCellViewModel] = []

   // MARK: - Callbacks
   var onDeleteTapped: ((Int) -> Void)?
   var onVerifyTapped: ((Int) -> Void)?

   // MARK: - Configuration
   func configure(with items: [UserDomainCellViewModel]) {
       self.items = items
   }

   func getItemsCount() -> Int {
       return items.count
   }

   // MARK: - ASCollectionDataSource
   func collectionNode(
       _ collectionNode: ASCollectionNode,
       numberOfItemsInSection section: Int
   ) -> Int {
       return items.count
   }

   func collectionNode(
       _ collectionNode: ASCollectionNode,
       nodeBlockForItemAt indexPath: IndexPath
   ) -> ASCellNodeBlock {
       let item = items[indexPath.item]
       let onDelete = onDeleteTapped
       let onVerify = onVerifyTapped

       return {
           return UserDomainCollectionCell(
               viewModel: item,
               onDelete: {
                   onDelete?(indexPath.item)
               },
               onVerify: {
                   onVerify?(indexPath.item)
               }
           )
       }
   }

   func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
       return 1
   }

   func collectionNode(
       _ collectionNode: ASCollectionNode,
       constrainedSizeForItemAt indexPath: IndexPath
   ) -> ASSizeRange {
       let width = collectionNode.bounds.width - 32
       return ASSizeRangeMake(
           CGSize(width: width, height: 0),
           CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
       )
   }
}

// MARK: - ============================================
// MARK: - DELEGATE
// MARK: - ============================================

protocol UserDomainDelegateProtocol: ASCollectionDelegate {
   var onItemSelected: ((Int) -> Void)? { get set }
   var onLoadMore: ((Int) -> Void)? { get set }
}

final class UserDomainDelegate: NSObject, UserDomainDelegateProtocol {

   // MARK: - Callbacks
   var onItemSelected: ((Int) -> Void)?
   var onLoadMore: ((Int) -> Void)?

   // MARK: - ASCollectionDelegate
   func collectionNode(
       _ collectionNode: ASCollectionNode,
       didSelectItemAt indexPath: IndexPath
   ) {
       onItemSelected?(indexPath.item)
   }

   func collectionNode(
       _ collectionNode: ASCollectionNode,
       willDisplayItemWith node: ASCellNode
   ) {
       guard let indexPath = collectionNode.indexPath(for: node) else { return }
       onLoadMore?(indexPath.item)
   }
}

// MARK: - ============================================
// MARK: - COLLECTION CELL
// MARK: - ============================================

final class UserDomainCollectionCell: ASCellNode {
   private let userDomainNode: UserDomainCellNode

   init(
       viewModel: UserDomainCellViewModel,
       onDelete: (() -> Void)? = nil,
       onVerify: (() -> Void)? = nil
   ) {
       self.userDomainNode = UserDomainCellNode(
           viewModel: viewModel,
           onDelete: onDelete,
           onVerify: onVerify
       )
       super.init()
       self.selectionStyle = .none
       self.addSubnode(self.userDomainNode)
   }

   override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
       return ASInsetLayoutSpec(insets: .zero, child: self.userDomainNode)
   }
}

// MARK: - ============================================
// MARK: - CELL NODE
// MARK: - ============================================

final class UserDomainCellNode: ASDisplayNode {
   private let viewModel: UserDomainCellViewModel
   private let onDelete: (() -> Void)?
   private let onVerify: (() -> Void)?

   private let domainLabel: ASTextNode
   private let stateLabel: ASTextNode
   private let dateLabel: ASTextNode
   private let deleteButton: ASButtonNode
   private let verifyButton: ASButtonNode
   private let containerNode: ASDisplayNode

   init(
       viewModel: UserDomainCellViewModel,
       onDelete: (() -> Void)?,
       onVerify: (() -> Void)?
   ) {
       self.viewModel = viewModel
       self.onDelete = onDelete
       self.onVerify = onVerify

       self.domainLabel = ASTextNode()
       self.stateLabel = ASTextNode()
       self.dateLabel = ASTextNode()
       self.deleteButton = ASButtonNode()
       self.verifyButton = ASButtonNode()
       self.containerNode = ASDisplayNode()

       super.init()

       automaticallyManagesSubnodes = true
       setupUI()
   }

   private func setupUI() {
       // Container styling
       containerNode.backgroundColor = .white
       containerNode.cornerRadius = 12
       containerNode.shadowColor = UIColor.black.cgColor
       containerNode.shadowOpacity = 0.1
       containerNode.shadowOffset = CGSize(width: 0, height: 2)
       containerNode.shadowRadius = 4

       // Configure labels
       domainLabel.attributedText = NSAttributedString(
           string: viewModel.domain,
           attributes: [
               .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
               .foregroundColor: UIColor.label
           ]
       )

       stateLabel.attributedText = NSAttributedString(
           string: viewModel.state,
           attributes: [
               .font: UIFont.systemFont(ofSize: 14),
               .foregroundColor: UIColor.hex(viewModel.stateColor)
           ]
       )

       dateLabel.attributedText = NSAttributedString(
           string: viewModel.createdAt,
           attributes: [
               .font: UIFont.systemFont(ofSize: 12),
               .foregroundColor: UIColor.secondaryLabel
           ]
       )

       // Configure buttons
       if viewModel.canDelete {
           deleteButton.setTitle("Delete", with: UIFont.systemFont(ofSize: 14), with: .systemRed, for: .normal)
           deleteButton.addTarget(self, action: #selector(handleDeleteTap), forControlEvents: .touchUpInside)
       }

       if viewModel.canVerify {
           verifyButton.setTitle("Verify", with: UIFont.systemFont(ofSize: 14), with: .systemBlue, for: .normal)
           verifyButton.addTarget(self, action: #selector(handleVerifyTap), forControlEvents: .touchUpInside)
       }
   }

   @objc private func handleDeleteTap() {
       onDelete?()
   }

   @objc private func handleVerifyTap() {
       onVerify?()
   }

   override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
       let infoStack = ASStackLayoutSpec.vertical()
       infoStack.spacing = 4
       infoStack.children = [domainLabel, stateLabel, dateLabel]

       let buttonStack = ASStackLayoutSpec.horizontal()
       buttonStack.spacing = 8

       var buttons: [ASLayoutElement] = []
       if viewModel.canVerify {
           buttons.append(verifyButton)
       }
       if viewModel.canDelete {
           buttons.append(deleteButton)
       }
       buttonStack.children = buttons

       let mainStack = ASStackLayoutSpec.horizontal()
       mainStack.spacing = 16
       mainStack.justifyContent = .spaceBetween
       mainStack.alignItems = .center
       mainStack.children = [infoStack, buttonStack]

       let contentInset = ASInsetLayoutSpec(
           insets: UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16),
           child: mainStack
       )

       containerNode.layoutSpecBlock = { _, _ in
           return contentInset
       }

       return ASInsetLayoutSpec(
           insets: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16),
           child: containerNode
       )
   }
}

// MARK: - ============================================
// MARK: - CONTROLLER
// MARK: - ============================================

final class UserDomainController: MainCollectionController {

   // MARK: - Dependencies
   private let presenter: UserDomainPresenter
   private let dataSource: UserDomainDataSource
   private let delegate: UserDomainDelegate

   // MARK: - Properties
   private var cancellables = Set<AnyCancellable>()
   weak var coordinator: UserDomainCoordinator?

   // MARK: - Computed Properties
   var collectionNode: ASCollectionNode {
       return node
   }

   // MARK: - Initialization
   init(presenter: UserDomainPresenter) {
       self.presenter = presenter
       self.dataSource = UserDomainDataSource()
       self.delegate = UserDomainDelegate()

       super.init(node: ASCollectionNode(collectionViewLayout: UserDomainCollectionLayout()))

       setupDataSource()
       setupDelegate()
   }

   // MARK: - Lifecycle
   override func viewDidLoad() {
       super.viewDidLoad()
       presenter.viewDidLoad()
   }

   // MARK: - Setup
   private func setupDataSource() {
       collectionNode.dataSource = dataSource

       // Handle delete action
       dataSource.onDeleteTapped = { [weak self] index in
           self?.presenter.didRequestDelete(at: index)
       }

       // Handle verify action
       dataSource.onVerifyTapped = { [weak self] index in
           self?.presenter.didRequestVerification(at: index)
       }
   }

   private func setupDelegate() {
       collectionNode.delegate = delegate

       // Handle item selection
       delegate.onItemSelected = { [weak self] index in
           self?.presenter.didSelectItem(at: index)
       }

       // Handle load more
       delegate.onLoadMore = { [weak self] index in
           self?.presenter.loadMoreIfNeeded(currentIndex: index)
       }
   }

   // MARK: - Bindings
   override func setupBindings() {
       // Bind view state
       presenter.viewStatePublisher
           .receive(on: DispatchQueue.main)
           .sink { [weak self] state in
               self?.handleViewState(state)
           }
           .store(in: &cancellables)

       // Bind items
       presenter.itemsPublisher
           .receive(on: DispatchQueue.main)
           .sink { [weak self] items in
               self?.handleItemsUpdate(items)
           }
           .store(in: &cancellables)
   }

   // MARK: - State Handling
   private func handleViewState(_ state: UserDomainViewState) {
       switch state {
       case .idle:
           hideLoadingIndicator()

       case .loading:
           showLoadingIndicator()

       case .loaded:
           hideLoadingIndicator()

       case .error(let message):
           hideLoadingIndicator()
           showError(message)

       case .deleting(let index):
           showDeletingIndicator(at: index)

       case .verifying(let index):
           showVerifyingIndicator(at: index)
       }
   }

   private func handleItemsUpdate(_ items: [UserDomainCellViewModel]) {
       let oldCount = dataSource.getItemsCount()
       dataSource.configure(with: items)
       let newCount = items.count

       if oldCount == 0 {
           // Initial load
           collectionNode.reloadData()
       } else if newCount > oldCount {
           // Pagination
           let indexPaths = (oldCount..<newCount).map { IndexPath(item: $0, section: 0) }
           collectionNode.performBatchUpdates({
               collectionNode.insertItems(at: indexPaths)
           })
       } else if newCount < oldCount {
           // Deletion
           let deletedIndex = oldCount - 1
           let indexPath = IndexPath(item: deletedIndex, section: 0)
           collectionNode.performBatchUpdates({
               collectionNode.deleteItems(at: [indexPath])
           })
       } else {
           // Update
           collectionNode.reloadData()
       }
   }

   // MARK: - UI Helpers
   private func showLoadingIndicator() {
       print("🔄 Loading...")
       // TODO: Show actual loading indicator
   }

   private func hideLoadingIndicator() {
       print("✅ Loading complete")
       // TODO: Hide loading indicator
   }

   private func showDeletingIndicator(at index: Int) {
       print("🗑️ Deleting item at \(index)")
       // TODO: Show deleting state for specific cell
   }

   private func showVerifyingIndicator(at index: Int) {
       print("🔍 Verifying item at \(index)")
       // TODO: Show verifying state for specific cell
   }

   private func showError(_ message: String) {
       let alert = UIAlertController(
           title: "Error",
           message: message,
           preferredStyle: .alert
       )
       alert.addAction(UIAlertAction(title: "OK", style: .default))
       present(alert, animated: true)
   }

   override func applyTheme(_ theme: Theme) {
       collectionNode.backgroundColor = theme.mainPresentationData.backgroundColor
   }

   required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
   }
}

// MARK: - ============================================
// MARK: - PRESENTER DELEGATE IMPLEMENTATION
// MARK: - ============================================

extension UserDomainController: UserDomainPresenterDelegate {
   func presenterDidSelectDomain(_ domain: UserDomain) {
       print("📱 Selected domain: \(domain.domain)")
       // Navigate to detail screen
       // coordinator?.showDomainDetail(domain)
   }

   func presenterDidRequestDeleteConfirmation(for domain: UserDomain, at index: Int) {
       let alert = UIAlertController(
           title: "Delete Domain",
           message: "Are you sure you want to delete '\(domain.domain)'?",
           preferredStyle: .alert
       )

       alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
       alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
           self?.presenter.didConfirmDelete(at: index)
       })

       present(alert, animated: true)
   }

   func presenterDidDeleteDomain() {
       showSuccessToast("Domain deleted successfully")
   }

   func presenterDidVerifyDomain(success: Bool) {
       if success {
           showSuccessToast("Domain verified successfully")
       } else {
           showInfoToast("Domain verification pending")
       }
   }

   private func showSuccessToast(_ message: String) {
       print("✅ \(message)")
       // TODO: Show actual toast
   }

   private func showInfoToast(_ message: String) {
       print("ℹ️ \(message)")
       // TODO: Show actual toast
   }
}

// MARK: - ============================================
// MARK: - CONTAINER FACTORY EXTENSION
// MARK: - ============================================

extension Container {
   func makeUserDomainPresenter() -> UserDomainPresenter {
       let viewModel = makeUserDomainViewModel()
       return UserDomainPresenterImpl(viewModel: viewModel)
   }

   func makeRefactoredUserDomainController() -> UserDomainController {
       let presenter = makeUserDomainPresenter()
       let controller = UserDomainController(presenter: presenter)

       // Set presenter delegate
       if let presenterImpl = presenter as? UserDomainPresenterImpl {
           presenterImpl.delegate = controller
       }

       return controller
   }
}

// MARK: - ============================================
// MARK: - COORDINATOR UPDATE
// MARK: - ============================================

extension UserDomainCoordinator {
   func startWithRefactoredArchitecture() {
       let controller = container.makeRefactoredUserDomainController()
       controller.coordinator = self
       navigationController.setViewControllers([controller], animated: false)
   }
}
