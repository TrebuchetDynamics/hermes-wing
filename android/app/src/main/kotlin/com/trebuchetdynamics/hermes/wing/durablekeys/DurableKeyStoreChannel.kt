package com.trebuchetdynamics.hermes.wing.durablekeys

import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.interfaces.ECPublicKey
import java.security.spec.ECGenParameterSpec

class DurableKeyStoreChannel : MethodChannel.MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isAvailable" -> result.success(isAvailable())
                "createEs256KeyPair" -> result.success(createEs256KeyPair(requireAlias(call).value))
                "signEs256" -> result.success(signEs256(requireAlias(call).value, requirePayload(call)))
                "deleteKey" -> {
                    deleteKey(requireAlias(call).value)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (error: IllegalArgumentException) {
            result.error("invalid_argument", error.message, null)
        } catch (error: Exception) {
            result.error("durable_key_store_error", error.message, null)
        }
    }

    private fun isAvailable(): Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.M

    private fun createEs256KeyPair(alias: String): Map<String, String> {
        val existing = publicKey(alias)
        if (existing != null) return publicJwk(existing)

        val generator = KeyPairGenerator.getInstance(
            KeyProperties.KEY_ALGORITHM_EC,
            ANDROID_KEY_STORE,
        )
        val spec = KeyGenParameterSpec.Builder(
            alias,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY,
        )
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setUserAuthenticationRequired(false)
            .build()
        generator.initialize(spec)
        val keyPair = generator.generateKeyPair()
        return publicJwk(keyPair.public as ECPublicKey)
    }

    private fun signEs256(alias: String, payload: ByteArray): ByteArray {
        if (payload.isEmpty()) throw IllegalArgumentException("canonicalPayload is required")
        val keyStore = keyStore()
        val privateKey = keyStore.getKey(alias, null)
            ?: throw IllegalArgumentException("No durable key exists for alias")
        val signature = Signature.getInstance("SHA256withECDSA")
        signature.initSign(privateKey as java.security.PrivateKey)
        signature.update(payload)
        return DurableKeySignatureEncoding.derToJose(signature.sign())
    }

    private fun deleteKey(alias: String) {
        val keyStore = keyStore()
        if (keyStore.containsAlias(alias)) keyStore.deleteEntry(alias)
    }

    private fun publicKey(alias: String): ECPublicKey? {
        val certificate = keyStore().getCertificate(alias) ?: return null
        return certificate.publicKey as? ECPublicKey
    }

    private fun publicJwk(publicKey: ECPublicKey): Map<String, String> {
        return mapOf(
            "kty" to "EC",
            "crv" to "P-256",
            "x" to DurableKeySignatureEncoding.p256CoordinateToBase64Url(publicKey.w.affineX),
            "y" to DurableKeySignatureEncoding.p256CoordinateToBase64Url(publicKey.w.affineY),
            "alg" to "ES256",
        )
    }

    private fun keyStore(): KeyStore {
        return KeyStore.getInstance(ANDROID_KEY_STORE).apply { load(null) }
    }

    private fun requireAlias(call: MethodCall): DurableKeyAlias {
        return DurableKeyAlias.parse(call.argument<String>("alias"))
    }

    private fun requirePayload(call: MethodCall): ByteArray {
        val payload = call.argument<ByteArray>("canonicalPayload")
            ?: throw IllegalArgumentException("canonicalPayload is required")
        return payload
    }

    companion object {
        private const val ANDROID_KEY_STORE = "AndroidKeyStore"
    }
}
