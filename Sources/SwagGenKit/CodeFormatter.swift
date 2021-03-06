//
//  CodeFormatter.swift
//  SwagGen
//
//  Created by Yonas Kolb on 3/12/2016.
//  Copyright © 2016 Yonas Kolb. All rights reserved.
//

import Foundation
import Swagger

public class CodeFormatter {

    let spec: SwaggerSpec

    public init(spec: SwaggerSpec) {
        self.spec = spec
    }

    var disallowedTypes: [String] {
        return []
    }

    public func getContext() -> [String: Any] {
        return getSpecContext().clean()
    }

    func getSpecContext() -> [String: Any?] {
        var context: [String: Any?] = [:]

        context["raw"] = spec.json
        context["operations"] = spec.operations.map(getOperationContext)
        context["tags"] = spec.opererationsByTag.map { ["name": $0, "operations": $1.map(getOperationContext)] }
        context["definitions"] = Array(spec.definitions.values).map(getSchemaContext)
        context["info"] = getSpecInfoContext(info: spec.info)
        context["host"] = spec.host
        context["basePath"] = spec.basePath
        context["baseURL"] = "\(spec.schemes.first ?? "http")://\(spec.host ?? "")\(spec.basePath ?? "")"
        context["enums"] = spec.enums.map(getValueContext)
        context["securityDefinitions"] = spec.securityDefinitions.map(getSecurityDefinitionContext)
        return context
    }

    func getSecurityDefinitionContext(name: String, securityDefinition: SecurityDefinition) -> [String: Any?] {
        var context: [String: Any?] = securityDefinition.jsonDictionary
        context["name"] = name
        return context
    }

    func getSpecInfoContext(info: SwaggerSpec.Info) -> [String: Any?] {
        var context: [String: Any?] = [:]

        context["title"] = info.title
        context["description"] = info.description
        context["version"] = info.version

        return context
    }

    func getEndpointContext(endpoint: Endpoint) -> [String: Any?] {
        var context: [String: Any?] = [:]
        context["path"] = endpoint.path
        context["methods"] = endpoint.operations.map(getOperationContext)
        return context
    }

    func getOperationContext(operation: Swagger.Operation) -> [String: Any?] {
        let successResponse = operation.responses.filter { $0.statusCode == 200 || $0.statusCode == 204 }.first
        var context: [String: Any?] = [:]

        if let operationId = operation.operationId {
            context["operationId"] = operationId
        } else {
            let pathParts = operation.path.components(separatedBy: "/")
            var pathName = pathParts.map{$0.upperCamelCased()}.joined(separator: "")
            pathName = pathName.replacingOccurrences(of: "\\{(.*)\\}", with: "By_$1", options: .regularExpression, range: nil)
            let generatedOperationId = operation.method.rawValue.lowercased() + pathName.upperCamelCased()
            context["operationId"] = generatedOperationId
        }

        context["raw"] = operation.json
        context["method"] = operation.method.rawValue.uppercased()
        context["path"] = operation.path
        context["description"] = operation.description
        context["tag"] = operation.tags.first
        context["tags"] = operation.tags
        context["params"] = operation.parameters.map(getParameterContext)
        context["hasBody"] = operation.parameters.filter{$0.parameterType == .body || $0.parameterType == .form}.count > 0
        context["nonBodyParams"] = operation.parameters.filter { $0.parameterType != .body}.map(getParameterContext)
        context["bodyParam"] = operation.getParameters(type: .body).map(getParameterContext).first
        context["pathParams"] = operation.getParameters(type: .path).map(getParameterContext)
        context["queryParams"] = operation.getParameters(type: .query).map(getParameterContext)
        context["formParams"] = operation.getParameters(type: .form).map(getParameterContext)
        context["headerParams"] = operation.getParameters(type: .header).map(getParameterContext)
        context["enums"] = operation.enums.map(getParameterContext)
        context["securityRequirement"] = operation.securityRequirements.map(getSecurityRequirementContext).first
        context["securityRequirements"] = operation.securityRequirements.map(getSecurityRequirementContext)
        context["responses"] = operation.responses.map(getResponseContext)
        context["successResponse"] = successResponse.flatMap(getResponseContext)
        context["successType"] = successResponse?.schema?.schema.flatMap(getSchemaType) ?? successResponse?.schema.flatMap(getValueType)

        return context
    }

    func getSecurityRequirementContext(securityRequirement: SecurityRequirement) -> [String: Any?] {
        var context: [String: Any?] = [:]
        context["name"] = securityRequirement.name
        context["scope"] = securityRequirement.scopes.first
        context["scopes"] = securityRequirement.scopes
        return context
    }

    func getResponseContext(response: Response) -> [String: Any?] {
        var context: [String: Any?] = [:]
        context["statusCode"] = response.statusCode
        context["schema"] = response.schema.flatMap(getValueContext)
        context["description"] = response.description
        return context
    }

    func getValueContext(value: Value) -> [String: Any?] {
        var context: [String: Any?] = [:]

        context["raw"] = value.json
        context["type"] = getValueType(value)
        context["name"] = getValueName(value)
        context["value"] = value.name
        context["required"] = value.required
        context["optional"] = !value.required
        context["enumName"] = getEnumName(value)
        context["description"] = value.description
        let enums = value.enumValues ?? value.arrayValue?.enumValues
        context["enums"] = enums?.map { ["name": getEnumCaseName($0), "value": $0] }
        context["arrayType"] = value.arraySchema.flatMap(getSchemaType)
        context["dictionaryType"] = value.dictionarySchema.flatMap(getSchemaType)
        context["isArray"] = value.type == "array"
        context["isDictionary"] = value.type == "object" && (value.dictionarySchema != nil || value.dictionaryValue != nil)
        context["isGlobal"] = value.isGlobal
        return context
    }

    func getParameterContext(parameter: Parameter) -> [String: Any?] {
        var context = getValueContext(value: parameter)

        context["parameterType"] = parameter.parameterType?.rawValue

        return context
    }

    func getPropertyContext(property: Property) -> [String: Any?] {
        return getValueContext(value: property)
    }

    func getSchemaContext(schema: Schema) -> [String: Any?] {
        var context: [String: Any?] = [:]
        context["raw"] = schema.json
        context["type"] = getSchemaType(schema)
        context["parent"] = schema.parent.flatMap(getSchemaContext)
        context["description"] = schema.description
        context["requiredProperties"] = schema.requiredProperties.map(getPropertyContext)
        context["optionalProperties"] = schema.optionalProperties.map(getPropertyContext)
        context["properties"] = schema.properties.map(getPropertyContext)
        context["allProperties"] = schema.allProperties.map(getPropertyContext)
        context["enums"] = schema.enums.map(getValueContext)
        return context
    }

    func escapeModelType(_ name: String) -> String {
        return "_\(name)"
    }

    func escapeEnumType(_ name: String) -> String {
        return "_\(name)"
    }

    func getSchemaType(_ schema: Schema) -> String {
        let type = schema.name.upperCamelCased()
        return disallowedTypes.contains(type) ? escapeModelType(type) : type
    }

    func getValueName(_ value: Value) -> String {
        return value.name.lowerCamelCased()
    }

    func getValueType(_ value: Value) -> String {
        if let object = value.schema {
            return getSchemaType(object)
        }
        if value.type == "unknown" {
            writeError("Couldn't calculate type")
        }
        return value.type
    }

    func getEnumName(_ value: Value) -> String {
        let name = (value.globalName ?? value.name).upperCamelCased()
        return disallowedTypes.contains(name) ? escapeEnumType(name) : name
    }

    func getEnumCaseName(_ name: String) -> String {
        return name.upperCamelCased()
    }
}

