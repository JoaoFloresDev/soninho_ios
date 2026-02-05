//
//  SleepTipsView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Sleep Tips View
struct SleepTipsView: View {
    // MARK: - Properties
    @State private var selectedCategory: SleepTip.TipCategory?
    private let tipsService = SleepTipsService.shared
    
    // MARK: - Computed Properties
    private var filteredTips: [SleepTip] {
        if let category = selectedCategory {
            return tipsService.getTipsForCategory(category)
        }
        return tipsService.getAllTips()
    }
    
    // MARK: - View Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Daily Tip Card
                dailyTipCard
                
                // Category Filter
                categoryFilter
                
                // Tips List
                tipsList
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.bottom, AppSpacing.tabBarBottomPadding)
        }
        .background(AppColors.background)
        .navigationTitle(String(localized: "tips_all_title"))
    }
    
    // MARK: - Daily Tip Card
    private var dailyTipCard: some View {
        let dailyTip = tipsService.getDailyTip()
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(AppColors.accent)
                
                Text(String(localized: "tips_daily_title"))
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
            }
            
            TipCard(tip: dailyTip, isExpanded: true)
        }
    }
    
    // MARK: - Category Filter
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(
                    title: String(localized: "action_all"),
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedCategory = nil
                    }
                }
                
                ForEach(SleepTip.TipCategory.allCases, id: \.self) { category in
                    FilterChip(
                        title: category.localizedName,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Tips List
    private var tipsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredTips) { tip in
                TipCard(tip: tip, isExpanded: false)
            }
        }
    }
}

// MARK: - Tip Card
struct TipCard: View {
    let tip: SleepTip
    let isExpanded: Bool
    
    @State private var showingDetail = false
    
    var body: some View {
        Button {
            HapticManager.lightImpact()
            showingDetail.toggle()
        } label: {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: tip.icon)
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 48, height: 48)
                    .background(AppColors.primary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: String.LocalizationValue(tip.title)))
                        .font(AppFonts.body())
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    if isExpanded || showingDetail {
                        Text(String(localized: String.LocalizationValue(tip.description)))
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                if !isExpanded {
                    Image(systemName: showingDetail ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: showingDetail)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.caption())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.primary : AppColors.surface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SleepTipsView()
    }
}
