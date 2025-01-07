import 'package:vania/src/view_engine/processor_engine/abs_processor.dart';
import 'package:vania/src/view_engine/processor_engine/variables_processor.dart';

import 'processor_engine/if_statement_processor.dart';
import 'processor_engine/extends_processor.dart';
import 'processor_engine/for_loop_processor.dart';
import 'processor_engine/include_processor.dart';
import 'processor_engine/section_processor.dart';
import 'processor_engine/switch_cases_processor.dart';
import 'template_reader.dart';

class _TemplateProcessingPipeline {
  final List<AbsProcessor> _processors;

  _TemplateProcessingPipeline(this._processors);

  String run(String content, Map<String, dynamic> data) {
    for (final processor in _processors) {
      content = processor.parse(content, data);
    }
    return content;
  }
}

class TemplateEngine {
  static final TemplateEngine _singleton = TemplateEngine._internal();
  factory TemplateEngine() => _singleton;
  TemplateEngine._internal();
  final VariablesProcessor _variablesProcess = VariablesProcessor();
  final IfStatementProcessor _conditionalProcess = IfStatementProcessor();
  final SwitchCasesProcessor _switchCaseProcess = SwitchCasesProcessor();
  final ForLoopProcessor _forLoopProcessor = ForLoopProcessor();
  final IncludeProcessor _includeProcessor = IncludeProcessor();
  final ExtendsProcessor _extendsProcessor = ExtendsProcessor();
  final SectionProcessor _sectionProcessor = SectionProcessor();

  String render(String template, [Map<String, dynamic>? data]) {
    String templateContent = FileTemplateReader().read(template);
    return renderString(templateContent, data);
  }

  /// Renders a template string with the provided data context.
  ///
  /// This function processes the template content by running it through a pipeline
  /// of processors, including extends, include, section, for loop, switch case,
  /// conditional, and variables processors. Each processor modifies the template
  /// content based on the provided context data.
  ///
  /// The context data is first merged with any child sections parsed from the template content.
  ///
  /// Returns the fully rendered content as a string.
  ///
  /// Parameters:
  /// - [templateContent]: The raw template content to be rendered.
  /// - [data] (optional): A map of context data to be used for rendering the template.
  ///   If not provided, an empty map is used.
  ///
  String renderString(String templateContent, [Map<String, dynamic>? data]) {
    data = {
      ...data ?? {},
      ..._sectionProcessor.parseChildSections(templateContent),
    };

    final pipeline = _TemplateProcessingPipeline([
      _extendsProcessor,
      _includeProcessor,
      _sectionProcessor,
      _forLoopProcessor,
      _switchCaseProcess,
      _conditionalProcess,
      _variablesProcess,
    ]);

    final renderedContent = pipeline.run(templateContent, data);
    return renderedContent;
  }
}
