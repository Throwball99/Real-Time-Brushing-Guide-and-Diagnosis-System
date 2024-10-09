import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_core/prompts.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:smartmirror_renewal/theme.dart';

import '../provider/firestore_provider.dart';

class ChatPage extends HookWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(title: Text("스마트 챗봇🤖", style: APPBAR_FONT),
        backgroundColor: Colors.white.withAlpha(100),
        elevation: 0.0,
        scrolledUnderElevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaY: 10, sigmaX: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: ChatWidget(apiKey: API_KEY),
    );
  }
}

class ChatWidget extends HookConsumerWidget {
  ChatWidget({Key? key, required this.apiKey}) : super(key: key);

  final String apiKey;
  final model = ChatGoogleGenerativeAI(apiKey: API_KEY);
  final FocusNode textFocus = FocusNode();

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final chatHistory = useState<List<Map<String, dynamic>>>([]);
    final textController = useTextEditingController();
    final scrollController = useScrollController();

    final model = ChatGoogleGenerativeAI(apiKey: apiKey);  //모델 선언
    const outputParser = StringOutputParser<ChatResult>(); //출력 파서 선언
    // final selectedTemplate = useState<String>('치아 관련 질문에 대답하는 챗봇 : {topic}'); //선택된 템플릿
    final vectorStore = MemoryVectorStore(embeddings: GoogleGenerativeAIEmbeddings(apiKey: API_KEY));  //벡터 저장소
    final retriever = vectorStore.asRetriever();

    void sendMessageWithData() async {
      final userText = textController.text;
      if (userText.isNotEmpty) {
        chatHistory.value = [
          ...chatHistory.value,
          {'text': userText, 'isFromUser': true}
        ];
        textController.clear();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });

        try {
          final setupAndRetrieval = Runnable.fromMap<String>({
            // 'context': retriever.pipe(
            //   Runnable.mapInput((_) => vectors.join('\n')),
            // ),
            'question': Runnable.passthrough(),
          });

          final promptTemplate = ChatPromptTemplate.fromTemplate(
              // 'context:\n{context} \n chat: {question}'
              '치아 관련 질문에 대답하는 챗봇. 사용자의 질문에 친절히 답하며 치아, 양치, 구강, 위생, 치과치료에 대한 주제 이외에는 답변 하지 않음.\n 답변 형식은 스마트 챗봇 : (대답)\n 사용자 질문 : {question}'
          );

          // final promptTemplate = ChatPromptTemplate.fromTemplate(selectedTemplate.value);
          // final promptValue = await promptTemplate.invoke({'topic': userText});
          // final result = await model.invoke(PromptValue.string(promptValue.toString()));
          // final parsedOutput = await outputParser.invoke(result);

          final chain = setupAndRetrieval
              .pipe(promptTemplate)
              .pipe(model)
              .pipe(outputParser);

          final res = await chain.invoke(userText);

          print(res);

          chatHistory.value = [
            ...chatHistory.value,
            {'text': res.toString(), 'isFromUser': false}
          ];
        } catch (e) {
          chatHistory.value = [
            ...chatHistory.value,
            {'text': e.toString(), 'isFromUser': false}
          ];
        }
      }
    }

    return GestureDetector(
      onTap: () => textFocus.unfocus(),
      child: Column(
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ElevatedButton(
              //   onPressed: () async {
              //     await vectorStore.addDocuments(
              //       documents: [
              //         allCategoriesJson,
              //       ],
              //     );
              //
              //     final loader = JsonLoader(
              //       'path/to/file.json',
              //     );
              //     // final documents = await loader.load();
              //   },
              //   child: Text('데이터 입력'),
              // ),
              // templateButton("Tell me a joke about {topic}", "Jokes"),
              // templateButton("Tell me a fact about {topic}", "Facts"),
              // templateButton("Give me advice about {topic}", "Advice"),
            ],
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: chatHistory.value.length,
              itemBuilder: (context, index) {
                final message = chatHistory.value[index];
                return Align(
                  alignment: message['isFromUser'] ? Alignment.centerRight : Alignment.centerLeft,
                  child:
                  Container(
                    margin: const EdgeInsets.all(8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: message['isFromUser'] ? MAIN_COLOR : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5, spreadRadius: 0.5,)],
                    ),
                    child: MarkdownBody(
                      data: message['text'],
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(color: message['isFromUser'] ? Colors.white : Colors.black),
                      ),
                    )
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    focusNode: textFocus,
                    decoration: InputDecoration(hintText: '대화를 시작하세요...'),
                    onSubmitted: (_) => sendMessageWithData(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: MAIN_COLOR),
                  onPressed: sendMessageWithData,
                ),
              ],
            ),
          ),
          SizedBox(height: 30)
        ],
      ),
    );
  }
}