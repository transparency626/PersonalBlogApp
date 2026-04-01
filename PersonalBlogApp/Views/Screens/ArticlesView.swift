import SwiftUI

struct ArticlesView: View {
    @ObservedObject var viewModel: BlogViewModel
    @State private var isComposerPresented = false
    @State private var postPendingDeletion: BlogPost?

    var body: some View {
        NavigationStack {
            AppBackground {
                Group {
                    if viewModel.latestPosts.isEmpty {
                        emptyState
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(
                                    title: "All Articles",
                                    subtitle: "现在这里已经不只是展示了，你可以直接新增并保存自己的博客内容。"
                                )

                                ForEach(viewModel.latestPosts) { post in
                                    NavigationLink {
                                        ArticleDetailView(post: post)
                                    } label: {
                                        PostRowCard(post: post)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            postPendingDeletion = post
                                        } label: {
                                            Label("Delete Post", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(20)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("Articles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isComposerPresented = true
                    } label: {
                        Label("New Post", systemImage: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $isComposerPresented) {
                PostComposerView(viewModel: viewModel)
            }
            .alert("删除这篇文章？", isPresented: deleteAlertBinding) {
                Button("取消", role: .cancel) {
                    postPendingDeletion = nil
                }
                Button("删除", role: .destructive) {
                    if let postPendingDeletion {
                        viewModel.deletePost(postPendingDeletion)
                    }
                    postPendingDeletion = nil
                }
            } message: {
                Text("删除后会同步从本地存储移除。")
            }
        }
    }

    private var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { postPendingDeletion != nil },
            set: { if !$0 { postPendingDeletion = nil } }
        )
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 42))
                .foregroundStyle(Color.accentColor)

            Text("还没有你自己的文章")
                .font(.title3.bold())

            Text("点右上角的写作按钮，发布第一篇内容。写完后会自动保存到本地。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("开始写作") {
                isComposerPresented = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

private struct PostComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BlogViewModel
    @State private var draft = BlogPostDraft()

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("标题", text: $draft.title)
                    TextField("副标题，不填会自动生成摘要", text: $draft.subtitle, axis: .vertical)
                    TextField("分类，例如 SwiftUI / Interview", text: $draft.category)
                    TextField("标签，用英文逗号分隔", text: $draft.tagsText)
                }

                Section("正文") {
                    TextEditor(text: $draft.content)
                        .frame(minHeight: 220)

                    Text("支持简单分段：用空行分开段落；如果某一行以 `## ` 开头，会被识别成新的章节标题。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("展示样式") {
                    Picker("主题", selection: $draft.selectedTheme) {
                        ForEach(BlogTheme.allCases) { theme in
                            Text(theme.title).tag(theme)
                        }
                    }

                    Toggle("设为首页 Featured 文章", isOn: $draft.isFeatured)

                    HStack {
                        Label("预计阅读时长", systemImage: "clock")
                        Spacer()
                        Text("\(draft.estimatedReadingTime) min")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("发布") {
                        viewModel.addPost(from: draft)
                        dismiss()
                    }
                    .disabled(!draft.isValid)
                }
            }
        }
    }
}
