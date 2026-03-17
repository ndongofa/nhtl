package com.nhtl.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

import com.nhtl.security.RestAccessDeniedHandler;
import com.nhtl.security.RestAuthenticationEntryPoint;
import com.nhtl.security.SupabaseJwtFilter;

@Configuration
public class SecurityConfig {

	private final SupabaseJwtFilter supabaseJwtFilter;
	private final RestAuthenticationEntryPoint restAuthenticationEntryPoint;
	private final RestAccessDeniedHandler restAccessDeniedHandler;

	public SecurityConfig(SupabaseJwtFilter supabaseJwtFilter,
			RestAuthenticationEntryPoint restAuthenticationEntryPoint,
			RestAccessDeniedHandler restAccessDeniedHandler) {
		this.supabaseJwtFilter = supabaseJwtFilter;
		this.restAuthenticationEntryPoint = restAuthenticationEntryPoint;
		this.restAccessDeniedHandler = restAccessDeniedHandler;
	}

	@Bean
	public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
		http
				// API stateless (JWT)
				.sessionManagement(sm -> sm.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

				// CORS/CSRF
				.cors(Customizer.withDefaults()).csrf(csrf -> csrf.disable())

				// JSON errors for 401/403
				.exceptionHandling(ex -> ex.authenticationEntryPoint(restAuthenticationEntryPoint)
						.accessDeniedHandler(restAccessDeniedHandler))

				// Autorisations
				.authorizeHttpRequests(auth -> auth.requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
						.requestMatchers("/", "/index.html").permitAll()
						.requestMatchers("/api/auth/login", "/api/auth/register").permitAll()
						.requestMatchers("/api/admin/**").hasRole("ADMIN")
						.requestMatchers("/api/commandes/**", "/api/transports/**").authenticated().anyRequest()
						.permitAll())

				// JWT filter
				.addFilterBefore(supabaseJwtFilter, UsernamePasswordAuthenticationFilter.class);

		return http.build();
	}
}